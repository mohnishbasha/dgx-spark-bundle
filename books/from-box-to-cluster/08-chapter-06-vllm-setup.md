# Chapter 6 — vLLM Inference Engine

## Overview

This chapter covers both vLLM deployment patterns available on the DGX Spark cluster. Section 6.2 covers the **active deployment**: four independent per-model vLLM processes, one per small model, spread across both Sparks. Sections 6.3+ cover the **reference deployment** via RayCluster for tensor-parallel serving of large models.

## Prerequisites

**For per-model deployment (Section 6.4 — active):**
- k3s cluster running with both nodes `Ready` (Chapter 4)
- GPU Operator installed (Chapter 4)
- HuggingFace token secret in `core-services` namespace

**For tensor-parallel via Ray (Sections 6.5+ — reference):**
- RayCluster `vllm-cluster` deployed and both pods `Running` (Chapter 5)
- Ray cluster resources showing `GPU: 2.0` (Chapter 5)
- HuggingFace token secret in place (Chapter 5)

---

## 6.1 What vLLM Provides

vLLM is a high-performance LLM inference engine built for production-scale serving. Its key capabilities in this cluster:

| Feature | Description |
|---------|-------------|
| **PagedAttention** | Manages GPU KV cache memory in pages, enabling higher concurrent request throughput |
| **Tensor parallelism** | Splits model weight tensors across multiple GPUs — critical for models larger than one GPU's memory |
| **OpenAI-compatible API** | Drop-in replacement for the OpenAI `v1/completions` and `v1/chat/completions` endpoints |
| **ARM64 native** | NVIDIA's vLLM image is built for Grace Blackwell — no emulation, full performance |
| **Continuous batching** | Dynamically batches incoming requests for maximum GPU utilization |

---

## 6.2 Active Deployment: Per-Model Independent vLLM Processes

The active cluster deployment runs each model as its own independent vLLM process in the `core-services` namespace. No Ray cluster is involved. Each Spark hosts 1–2 models:

```
Spark 1 (192.168.86.30)               Spark 2 (192.168.86.26)
  core-services namespace                core-services namespace
  ├── qwen-3b  deployment                ├── gemma-2b  deployment
  │   └── vLLM process (port 8000)       │   └── vLLM process (port 8000)
  └── smollm-1b deployment               └── falcon-3b deployment
      └── vLLM process (port 8001)           └── vLLM process (port 8001)
```

Each model is deployed as a standard Kubernetes `Deployment` with a `Service` exposing its port. AIBrix (Chapter 7) sits in front and routes requests to the correct model by name.

### Deploying a single per-model vLLM instance

```bash
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: qwen-3b
  namespace: core-services
spec:
  replicas: 1
  selector:
    matchLabels:
      app: qwen-3b
  template:
    metadata:
      labels:
        app: qwen-3b
    spec:
      nodeSelector:
        kubernetes.io/hostname: spark-720e   # pin to Spark 1
      containers:
      - name: vllm
        image: nvcr.io/nvidia/vllm:25.09-py3
        command: ["python3", "-m", "vllm.entrypoints.openai.api_server"]
        args:
        - "--model=Qwen/Qwen2.5-3B-Instruct"
        - "--host=0.0.0.0"
        - "--port=8000"
        - "--gpu-memory-utilization=0.40"   # share GPU with co-hosted model
        - "--max-num-seqs=4"
        env:
        - name: HF_TOKEN
          valueFrom:
            secretKeyRef:
              name: hf-token
              key: token
        resources:
          limits:
            nvidia.com/gpu: "1"
        ports:
        - containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: qwen-3b-svc
  namespace: core-services
spec:
  selector:
    app: qwen-3b
  ports:
  - port: 8000
    targetPort: 8000
EOF
```

**Key differences from the tensor-parallel setup:**

| | Per-model (active) | Tensor-parallel via Ray (reference) |
|--|--|--|
| GPU memory per model | Fraction of one Spark's 128GB | Full 256GB combined |
| Cross-node comms | None | NCCL over network for every inference call |
| Model size | Fits on one GPU (3B–13B typical) | Up to 256GB (70B–235B) |
| Resilience | One model can fail independently | Both Sparks must be up |
| Setup complexity | Standard Kubernetes Deployment | KubeRay + RayCluster (Chapter 5) |

For two models sharing one Spark, set `--gpu-memory-utilization` to ≤0.45 each (leaving overhead for the OS and driver).

> **Production Note: Model weight persistence across pod restarts**
>
> By default, vLLM pods use ephemeral storage. When a pod is deleted or restarted, all downloaded model weights are lost. On next startup, the pod will re-download the full model from HuggingFace — 14GB for a 7B model, 140GB+ for larger models.
>
> To avoid this, mount the HuggingFace cache directory from the node's NVMe SSD using a `hostPath` volume:
> ```yaml
> volumes:
> - name: hf-cache
>   hostPath:
>     path: /home/moonlit/.cache/huggingface
>     type: DirectoryOrCreate
> # In the container spec:
> volumeMounts:
> - name: hf-cache
>   mountPath: /root/.cache/huggingface
> ```
> This pins model weights to the node's local disk. When the pod restarts, it finds the weights cached at the same path and skips the download. The tradeoff: if Kubernetes reschedules the pod to the other Spark, the cache is not there. The `nodeSelector` in the manifest prevents this for per-model deployments.
>
> For a production setup with shared storage, a Kubernetes PersistentVolumeClaim backed by NFS or a distributed filesystem is the right solution — but for a 2-node cluster, hostPath is simpler and faster.

---

## 6.3 Reference Deployment: Tensor Parallelism Architecture

With tensor parallelism across two nodes (requires KubeRay from Chapter 5):

```
Ray Head Pod (Spark 1 — 192.168.86.30)
├── Ray head node (port 6379) — cluster coordinator
├── Ray dashboard (port 8265) — web UI
└── vLLM API server (port 8000) — client-facing endpoint
    └── Tensor parallel rank 0 — holds first half of model weights on Spark 1 GPU

Ray Worker Pod (Spark 2 — 192.168.86.26)
└── Tensor parallel rank 1 — holds second half of model weights on Spark 2 GPU

Total GPU memory used: ~14GB for Qwen2.5-7B in bf16 (7B params × 2 bytes)
Memory per GPU (rank): ~7GB weights + KV cache allocation (controlled by --gpu-memory-utilization)
```

During inference, each forward pass requires both GPUs to compute their portion of each transformer layer and synchronize intermediate activations via an all-reduce operation. This communication happens over NCCL, which currently falls back to TCP over the Flannel network. RDMA over the ConnectX-7 interconnect will dramatically improve this throughput in a future RKE2 + Cilium migration.

> **Deep Dive: How tensor parallelism splits a transformer layer**
>
> Tensor parallelism does not simply cut the model in half by layer count (that is pipeline parallelism). Instead, each transformer layer's weight matrices are split column-wise (for attention projections and FFN weights) across both GPUs. Every forward pass through a layer requires:
> 1. Each GPU computes its column partition locally (no communication)
> 2. An all-reduce across both GPUs to sum the partial results (communication step)
> 3. The combined result feeds the next layer
>
> For a 7B model, this means hundreds of all-reduce calls per inference request. With TCP over Flannel (~10Gbps), these add measurable latency per token. With RDMA over ConnectX-7 (~400Gbps theoretical), the communication overhead becomes negligible — which is why RDMA matters more for tensor-parallel workloads than for independent per-model deployments.

---

## 6.4 Image Details

The NVIDIA vLLM image used in Chapter 5:

```
nvcr.io/nvidia/vllm:25.09-py3
```

| Component | Version |
|-----------|---------|
| vLLM | 0.10.1.1 |
| Ray | 2.49.2 |
| CUDA | 13.0 |
| Python | 3.x |
| Architecture | ARM64 (aarch64) |

---

## 6.5 vLLM Startup Sequence

After the Ray head pod starts, it executes:

1. `ray start --head --num-gpus=1 --block &` — starts the Ray head node in background
2. `sleep 30` — waits for Ray to initialize cluster membership
3. `python3 -m vllm.entrypoints.openai.api_server ...` — starts vLLM

**First-time startup** (model needs to be downloaded from HuggingFace):

| Phase | Time |
|-------|------|
| Model download (14GB for 7B) | ~20 minutes |
| Model loading into GPU memory | ~3 minutes |
| Tensor parallel initialization | ~2 minutes |
| **Total first start** | **~25 minutes** |

**Subsequent startups** (model cached in the pod's ephemeral storage or a PVC):

| Phase | Time |
|-------|------|
| Model load from cache | ~2 minutes |
| Tensor parallel init | ~2 minutes |
| **Total** | **~3–5 minutes** |

---

## 6.6 Key vLLM Configuration Flags

```bash
python3 -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-7B-Instruct \    # HuggingFace model ID
  --tensor-parallel-size 2 \             # one rank per GPU/node
  --distributed-executor-backend ray \   # use Ray for distribution
  --host 0.0.0.0 \                      # bind to all interfaces
  --port 8000 \                          # API port
  --gpu-memory-utilization 0.85 \       # 85% of GPU memory for KV cache
  --max-num-seqs 4                       # max concurrent sequences
```

**Tuning `--gpu-memory-utilization`:**
- Higher values (0.90–0.95) allow more concurrent requests but reduce headroom
- Lower values (0.70–0.80) are safer during initial testing
- 0.85 is a stable default for development workloads

**Tuning `--max-num-seqs`:**
- This caps concurrent in-flight requests
- Start at 4 and increase as you verify stability
- Higher values require more KV cache memory

---

## 6.7 Monitoring Startup

Watch the head pod logs to monitor the startup sequence:

```bash
# Stream logs from the Ray head pod
kubectl logs -n core-services \
  -l ray.io/node-type=head \
  --follow
```

Look for these key log lines:

```
# Ray initialized:
Started GCS server.
...
Ray runtime started with 1 GPU.

# vLLM loading model:
Loading model weights...
Loading safetensors checkpoint...

# vLLM tensor parallel setup:
Initializing tensor parallel group with ranks [0, 1]

# Ready to serve:
Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

The last two lines confirm vLLM is ready.

---

## 6.8 Verification

### Check Pod Status

```bash
kubectl get pods -n core-services -o wide
# Expected: both pods Running, no restarts
```

### Test Model Endpoint

```bash
HEAD=$(kubectl get pods -n core-services -l ray.io/node-type=head -o name | head -1)

# List available models
kubectl exec -n core-services $HEAD -- \
  curl -s http://localhost:8000/v1/models | python3 -m json.tool
```

Expected:

```json
{
  "object": "list",
  "data": [
    {
      "id": "Qwen/Qwen2.5-7B-Instruct",
      "object": "model",
      ...
    }
  ]
}
```

### Test Chat Completion

```bash
kubectl exec -n core-services $HEAD -- \
  curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen2.5-7B-Instruct",
    "messages": [{"role": "user", "content": "What is tensor parallelism?"}],
    "max_tokens": 100
  }' | python3 -m json.tool
```

A successful response with generated text confirms the full stack is working end to end.

---

## 6.9 Kubernetes Services

Two services expose vLLM within the cluster:

```bash
kubectl get services -n core-services
```

```
NAME                    TYPE        CLUSTER-IP     PORT(S)
vllm-cluster-head-svc   ClusterIP   None           10001,8265,6379,8080,8000
vllm-service            ClusterIP   10.43.55.139   8000
```

| Service | Type | Purpose |
|---------|------|---------|
| `vllm-cluster-head-svc` | Headless | Ray worker uses this DNS to find the head node |
| `vllm-service` | ClusterIP | Other cluster pods call vLLM API on `vllm-service:8000` |

**Using from another pod in the cluster:**

```bash
curl http://vllm-service.core-services.svc.cluster.local:8000/v1/models
```

---

## 6.10 Serving Different Models

To change the model, update the `--model` flag in the RayCluster manifest and reapply:

```bash
kubectl delete raycluster vllm-cluster -n core-services
# Wait for pods to terminate, then re-apply with new model
```

**Model examples:**

| Model | HuggingFace ID | Notes |
|-------|---------------|-------|
| Qwen2.5-7B (default) | `Qwen/Qwen2.5-7B-Instruct` | Fast, fits easily |
| Qwen2.5-72B | `Qwen/Qwen2.5-72B-Instruct` | Needs `--max-model-len` flag |
| Llama 3.3 70B | `meta-llama/Llama-3.3-70B-Instruct` | Needs HF access request |
| Mistral 7B | `mistralai/Mistral-7B-Instruct-v0.3` | Alternative to Qwen |

**For models requiring quantization** (to fit within 256GB):

```bash
--quantization awq           # AWQ quantization
--quantization nvfp4         # NVFP4 (NVIDIA native, best performance)
```

---

## 6.11 Ray Dashboard

The Ray dashboard provides a web UI showing cluster resources, running tasks, and actor status:

```bash
# Port-forward the Ray dashboard
HEAD=$(kubectl get pods -n core-services -l ray.io/node-type=head -o name | head -1)
kubectl port-forward -n core-services $HEAD 8265:8265
```

Open `http://localhost:8265` in your browser to see the Ray cluster state.

---

## 6.12 Version Prerequisites

| Component | Minimum | This Setup |
|-----------|---------|-----------|
| NVIDIA Driver | 525+ | 580.159.03 |
| CUDA | 12.1+ | 13.0 |
| Kubernetes | 1.27+ | 1.35.5 |
| Ray | 2.x | 2.49.2 |
| vLLM | 0.6+ | 0.10.1.1 |

---

## Summary

At the end of this chapter you have:

- [x] vLLM serving `Qwen/Qwen2.5-7B-Instruct` on port 8000 within the cluster
- [x] `/v1/models` endpoint returning the model list
- [x] `/v1/chat/completions` returning generated text
- [x] Tensor parallelism across both GB10 GPUs confirmed
- [x] Kubernetes services providing internal cluster access to the API

---

*Continue to Chapter 7 to install AIBrix and add an AI gateway layer for request routing and multi-tenancy.*
