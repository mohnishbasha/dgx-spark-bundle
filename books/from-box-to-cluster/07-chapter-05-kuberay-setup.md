# Chapter 5 — KubeRay for Distributed AI

## Overview

This chapter installs the KubeRay operator and deploys a 2-node Ray cluster that spans both DGX Sparks. vLLM (Chapter 6) can run inside this Ray cluster, using it for tensor parallelism across both GPUs.

> **Reference path — read this first.** KubeRay is installed on the cluster and fully functional, but it is the *reference deployment path*, not the currently active inference route. The live cluster serves 4 small models as independent per-model vLLM processes (see Chapter 6, Section 6.4). Come back to this chapter when you need to serve **a single model larger than ~100–120B parameters** that exceeds one Spark's 128GB unified memory.
>
> **When you'd use this instead of per-model vLLM:**
> - Hosting one large model (Qwen3-235B-A22B, Nemotron-3-Super-120B, a quantized 70B+ model) that needs both Sparks' combined 256GB
> - Workloads that need one model at higher throughput/quality rather than multiple small models running independently
> - Any future project where a single model weight file won't fit on one Spark

## Prerequisites

- k3s cluster running with both nodes `Ready` (Chapter 4)
- NVIDIA GPU Operator installed and GPUs visible (Chapter 4)
- Helm installed (Chapter 4)
- NVIDIA NGC account (for pulling the ARM64-native image)

---

## 5.1 What KubeRay Does

KubeRay is a Kubernetes operator that manages the lifecycle of Ray clusters inside Kubernetes. Without KubeRay, you would need to manually manage Ray node processes, handle failures, and coordinate resource allocation — KubeRay automates all of this.

**In this cluster:**
- KubeRay deploys a Ray head pod on Spark 1 (which also runs the vLLM API server)
- KubeRay deploys a Ray worker pod on Spark 2
- vLLM uses Ray to distribute tensor parallel workloads across both pods
- KubeRay handles restarts, health checks, and resource requests automatically

```
KubeRay Operator (Spark 1, kuberay-system namespace)
        │ manages
        ▼
RayCluster "vllm-cluster" (core-services namespace)
├── Ray Head Pod (Spark 1) — coordinates cluster + runs vLLM API server
└── Ray Worker Pod (Spark 2) — tensor parallel rank 1
```

---

## 5.2 Critical: ARM64 Architecture Warning

> **This is the most common failure point for DGX Spark setups.**

The standard Ray Docker image (`rayproject/ray`) is **x86_64 only**. On DGX Spark's ARM64 architecture, it will either:
- Fail to pull with "no matching manifest for linux/arm64"
- Pull an emulated version that crashes with "exec format error" at runtime

**Always use the NVIDIA vLLM image for both Ray head and worker:**

```
nvcr.io/nvidia/vllm:25.09-py3
```

This image is:
- ARM64 native (Grace Blackwell compatible)
- Contains Ray 2.49.2 pre-installed
- Contains vLLM 0.10.1.1 pre-installed
- Contains CUDA 13.0

Every RayCluster manifest in this book uses this image. Do not substitute with `rayproject/ray` or any other image.

---

## 5.3 Install KubeRay Operator

```bash
helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update

helm install kuberay-operator kuberay/kuberay-operator \
  --namespace kuberay-system \
  --create-namespace \
  --set nodeSelector."kubernetes\\.io/hostname"=spark-720e
```

The `nodeSelector` pins the KubeRay operator itself to Spark 1. The operator only coordinates; it does not need to run on both nodes.

Verify the operator pod is running:

```bash
kubectl get pods -n kuberay-system
# Expected:
# NAME                               READY   STATUS    AGE
# kuberay-operator-xxxxxxxxx-xxxxx   1/1     Running   Xm
```

---

## 5.4 NVIDIA NGC Registry Login and Image Pull Secret

The NVIDIA vLLM image is hosted on NVIDIA's private container registry (NGC). You need an NGC API key to pull it.

**Get an API key:**
1. Go to `ngc.nvidia.com`
2. Sign in (create a free account if needed)
3. Navigate to **Setup** → **Generate Personal Key**
4. Select **NGC Catalog** scope
5. Copy the generated key

**Login via Docker (for manual image pulls and testing):**

```bash
# On Spark 1
docker login nvcr.io
# Username: $oauthtoken
# Password: <paste your NGC API key>

# On Spark 2 (via SSH)
ssh moonlit@192.168.86.26 "docker login nvcr.io"
```

> **Note:** The username is literally `$oauthtoken` — that is not a variable, it is the actual username string required by NGC.

**Create a Kubernetes image pull secret (required for containerd):**

k3s uses containerd to pull images for pods — not Docker. containerd does not read Docker's credential file. You must create a Kubernetes secret so that pod specs can reference it during image pull:

```bash
kubectl create secret docker-registry ngc-registry \
  --docker-server=nvcr.io \
  --docker-username='$oauthtoken' \
  --docker-password='<YOUR_NGC_API_KEY>' \
  -n core-services
```

This secret is referenced in the RayCluster manifest in Section 5.7. Without it, pods will fail with `ImagePullBackOff` even if your Docker login succeeded.

> **Common Pitfall: Docker login ≠ containerd credentials**
>
> This trips up almost everyone coming from Docker-based workflows. `docker login` writes to `~/.docker/config.json`. containerd reads from a separate credential store configured in `/etc/containerd/config.toml`. For Kubernetes workloads, the correct approach is always the `imagePullSecrets` pattern shown above — it works regardless of what is installed on the node.

---

## 5.5 Validate Cross-Node Networking

Before deploying the Ray cluster, verify that pods scheduled on different nodes can communicate. This confirms Flannel CNI is working correctly across the QSFP interconnect.

```bash
# Deploy a test pod on Spark 1
kubectl run test-spark1 \
  --image=busybox \
  --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"spark-720e"}}}' \
  --command -- sleep 3600

# Deploy a test pod on Spark 2
kubectl run test-spark2 \
  --image=busybox \
  --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"spark-7229"}}}' \
  --command -- sleep 3600

# Wait for both pods to be Running
kubectl get pods -o wide
```

Copy the IP address of `test-spark2` from the output (CLUSTER-IP column), then:

```bash
# Ping from Spark 1 pod to Spark 2 pod
kubectl exec test-spark1 -- ping -c 4 <SPARK2_POD_IP>

# Expected: 4 packets transmitted, 4 received, 0% packet loss
```

Clean up:

```bash
kubectl delete pod test-spark1 test-spark2
```

If the ping fails, check that both nodes are `Ready`, the GPU Operator DaemonSets are running on both nodes, and Flannel pods are running in `kube-system`.

---

## 5.6 Create the HuggingFace Token Secret

vLLM downloads model weights from HuggingFace on first startup. Create the secret now (in the `core-services` namespace where the Ray cluster will run):

```bash
export HF_TOKEN="hf_your_token_here"

kubectl create secret generic hf-token \
  --from-literal=token=$HF_TOKEN \
  -n core-services
```

Get a HuggingFace token at `huggingface.co` → Settings → Access Tokens. A read-only token is sufficient.

> **Security:** Never hardcode the token in manifests or commit it to Git. The Kubernetes secret is injected as an environment variable at runtime.

---

## 5.7 Deploy the RayCluster

Apply the RayCluster manifest. This creates a Ray head pod on Spark 1 and a Ray worker pod on Spark 2:

```bash
kubectl apply -f - <<'EOF'
apiVersion: ray.io/v1
kind: RayCluster
metadata:
  name: vllm-cluster
  namespace: core-services
spec:
  rayVersion: '2.49.2'
  headGroupSpec:
    rayStartParams:
      dashboard-host: '0.0.0.0'
      num-gpus: '1'
    template:
      spec:
        nodeSelector:
          kubernetes.io/hostname: spark-720e
        containers:
        - name: ray-head
          image: nvcr.io/nvidia/vllm:25.09-py3
          command: ["/bin/bash", "-c"]
          args:
          - |
            ray start --head \
              --dashboard-host=0.0.0.0 \
              --num-gpus=1 \
              --block &
            RAY_PID=$!
            echo "Waiting for Ray to be ready..."
            sleep 30
            echo "Starting vLLM..."
            python3 -m vllm.entrypoints.openai.api_server \
              --model Qwen/Qwen2.5-7B-Instruct \
              --tensor-parallel-size 2 \
              --distributed-executor-backend ray \
              --host 0.0.0.0 \
              --port 8000 \
              --gpu-memory-utilization 0.85 \
              --max-num-seqs 4
          env:
          - name: HF_TOKEN
            valueFrom:
              secretKeyRef:
                name: hf-token
                key: token
          resources:
            limits:
              nvidia.com/gpu: "1"
              memory: "100Gi"
            requests:
              nvidia.com/gpu: "1"
              memory: "100Gi"
          ports:
          - containerPort: 8000
          - containerPort: 8265
  workerGroupSpecs:
  - replicas: 1
    minReplicas: 1
    maxReplicas: 1
    groupName: worker-group
    rayStartParams:
      num-gpus: '1'
    template:
      spec:
        nodeSelector:
          kubernetes.io/hostname: spark-7229
        containers:
        - name: ray-worker
          image: nvcr.io/nvidia/vllm:25.09-py3
          command: ["/bin/bash", "-c"]
          args:
          - |
            ray start \
              --address=vllm-cluster-head-svc.core-services.svc.cluster.local:6379 \
              --num-gpus=1 \
              --block
          env:
          - name: HF_TOKEN
            valueFrom:
              secretKeyRef:
                name: hf-token
                key: token
          resources:
            limits:
              nvidia.com/gpu: "1"
              memory: "100Gi"
            requests:
              nvidia.com/gpu: "1"
              memory: "100Gi"
EOF
```

**Key design decisions in this manifest:**

| Decision | Why |
|----------|-----|
| `nodeSelector` for each pod | Pins head to Spark 1, worker to Spark 2 — ensures tensor parallel ranks land on different nodes |
| Explicit DNS for worker address | `$RAY_HEAD_SERVICE_HOST` env var is unreliable in k3s; hardcoding the service DNS name is more robust |
| 100Gi memory request | Leaves headroom for OS and GPU driver processes on each 128GB node |
| 85% GPU memory utilization | Allows OS/driver overhead on each GPU |
| max-num-seqs 4 | Caps concurrent sequences during initial testing — adjust up once stable |

> **Production Note: NCCL network interface selection**
>
> By default, NCCL (used by vLLM for tensor parallel all-reduce) will attempt to auto-detect the best network interface for cross-node communication. In a k3s/Flannel environment with multiple interfaces (Ethernet, Flannel VXLAN, loopback), NCCL can select the wrong one — causing dramatically reduced throughput or hangs.
>
> Add these environment variables to the head and worker container specs to force NCCL onto the correct interface:
> ```yaml
> env:
> - name: NCCL_SOCKET_IFNAME
>   value: "eth0"          # replace with your actual Ethernet interface name
> - name: NCCL_DEBUG
>   value: "INFO"          # enable on first run to verify interface selection
> - name: NCCL_IB_DISABLE
>   value: "1"             # disable InfiniBand path (use IP fallback via Flannel)
> ```
>
> To find your interface name on each Spark:
> ```bash
> ip link show | grep -E "^[0-9]+:" | awk -F': ' '{print $2}'
> # Typical output on DGX Spark: lo, eth0, flannel.1, cni0
> # Use eth0 (or the physical Ethernet interface) for NCCL_SOCKET_IFNAME
> ```
>
> Once RDMA is enabled in a future RKE2 + Cilium migration, remove `NCCL_IB_DISABLE` and set `NCCL_SOCKET_IFNAME` to the RDMA interface for full ConnectX-7 throughput.

---

## 5.8 Verify the Ray Cluster

```bash
# Check both pods are Running
kubectl get pods -n core-services -o wide
# Expected:
# vllm-cluster-head-xxxxx    1/1   Running   Spark 1 IP
# vllm-cluster-worker-xxxxx  1/1   Running   Spark 2 IP

# Verify Ray sees both nodes and both GPUs
HEAD=$(kubectl get pods -n core-services -l ray.io/node-type=head -o name | head -1)
kubectl exec -n core-services $HEAD -- python3 -c \
  "import ray; ray.init(); print(ray.cluster_resources())"
```

Expected output should include:

```
{
  'GPU': 2.0,
  'CPU': 40.0,
  'accelerator_type:GB10': 2.0,
  'memory': ...,
  'object_store_memory': ...
}
```

If `GPU` shows `1.0` instead of `2.0`, the worker pod is not connected. Check worker pod logs:

```bash
kubectl logs -n core-services -l ray.io/node-type=worker --tail=20
```

---

## 5.9 Troubleshooting

### Worker fails with "exec format error"

The image you specified is x86-only. Confirm the image is:
```
nvcr.io/nvidia/vllm:25.09-py3
```

### Worker fails with "Malformed host" or connection refused

The `$RAY_HEAD_SERVICE_HOST` environment variable is empty or incorrect. The manifest above uses the explicit DNS name, which avoids this. If using a custom manifest, always use:
```
vllm-cluster-head-svc.core-services.svc.cluster.local:6379
```

### Worker fails with "Failed to validate connection to cluster"

The head service IP may have changed (network change between sessions). Check current service IPs:

```bash
kubectl get services -n core-services
```

### NGC image pull fails

Ensure docker login was done on the Spark where the worker is scheduled (Spark 2). The containerd runtime used by k3s uses a different credential store than Docker — see the note below.

> **containerd vs Docker credentials:** k3s uses containerd, not Docker. For the image pull to work with containerd, you may need to create a registry secret:
> ```bash
> kubectl create secret docker-registry ngc-registry \
>   --docker-server=nvcr.io \
>   --docker-username='$oauthtoken' \
>   --docker-password='<YOUR_NGC_API_KEY>' \
>   -n core-services
> ```
> Then add `imagePullSecrets` to the pod spec in the manifest.

---

## Summary

At the end of this chapter you have:

- [x] KubeRay operator running in `kuberay-system`
- [x] Cross-node pod networking verified
- [x] HuggingFace token stored as Kubernetes secret
- [x] RayCluster deployed with head on Spark 1 and worker on Spark 2
- [x] Ray sees `GPU: 2.0` and `CPU: 40.0` (both nodes combined)

---

*Continue to Chapter 6 to verify vLLM is serving model completions over the OpenAI-compatible API.*
