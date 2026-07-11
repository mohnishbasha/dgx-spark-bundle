# Chapter 9 — System Architecture

## Overview

This chapter provides a layered view of the complete cluster: what lives in GitHub, what is physical hardware, what runs as cluster-wide infrastructure, and what actually executes as active workloads. Use this as an operational reference when reasoning about where things run and how they relate.

---

## 9.1 Complete Architecture Diagram

```
GitHub repo (dgx-spark-bundle/books/from-box-to-cluster/)
│   docs/              ← infra + pipeline documentation (this ebook)
│   research/          ← long-form research artifacts
│   social/            ← short-form content artifacts
│          ↓
│   manual kubectl / helm apply from Spark 1
│   (no GitOps operator — no ArgoCD, no Flux)
─────────────────────────────────────────────────────────────────
PHYSICAL HARDWARE

Spark 1 (spark-720e, 192.168.86.30)
  1× GB10 Blackwell GPU · 128GB unified memory · 20-core ARM64
        ──────── QSFP ConnectX-7 RDMA ────────
Spark 2 (spark-7229, 192.168.86.26)
  1× GB10 Blackwell GPU · 128GB unified memory · 20-core ARM64

─────────────────────────────────────────────────────────────────
INFRASTRUCTURE LAYER (cluster-wide, both nodes)

k3s v1.35.5 + Flannel CNI
NVIDIA GPU Operator (device plugin, container toolkit, DCGM)
Prometheus + Grafana (monitoring namespace)

─────────────────────────────────────────────────────────────────
WORKLOAD LAYER

namespace: core-services
├── qwen-3b     — independent vLLM process on Spark 1
├── smollm-1b   — independent vLLM process on Spark 1
├── gemma-2b    — independent vLLM process on Spark 2
└── falcon-3b   — independent vLLM process on Spark 2
      (each model = its own Deployment + Service, NOT tensor-parallel)

namespace: aibrix-system
└── AIBrix — routing + quota layer, sits in front of core-services

namespace: kuberay-system
└── KubeRay operator — installed, reference path only
      (tensor-parallel vLLM-over-Ray: see Chapters 5–6,
       not the live deployment — see core-services above)

namespace: monitoring
├── Prometheus
└── Grafana

─────────────────────────────────────────────────────────────────
MANAGEMENT LAYER

Manual kubectl / Helm from Spark 1
No ArgoCD or GitOps operator currently deployed
```

---

## 9.2 Active Inference Architecture

The live cluster serves 4 small models as independent vLLM processes. Each model has its own GPU allocation, its own port, and its own Kubernetes Deployment and Service.

```
Spark 1 (192.168.86.30)                Spark 2 (192.168.86.26)
GPU: 128GB unified (shared ~50/50)      GPU: 128GB unified (shared ~50/50)
│                                       │
├── Deployment: qwen-3b                 ├── Deployment: gemma-2b
│   vLLM, port 8000, ~40% GPU           │   vLLM, port 8000, ~40% GPU
│                                       │
└── Deployment: smollm-1b              └── Deployment: falcon-3b
    vLLM, port 8001, ~40% GPU              vLLM, port 8001, ~40% GPU
         │                                      │
         └──────── AIBrix Gateway ──────────────┘
                  (aibrix-system)
                  Routes by model name
```

**Key design facts:**
- vLLM is **not** a shared service or a namespace. It is the inference engine inside each model's Deployment pod.
- Each model's pod is pinned to its Spark via `nodeSelector` (not auto-scheduled by the default scheduler, to prevent colocation conflicts).
- `--gpu-memory-utilization 0.40` caps each model at ~51GB of the 128GB GPU, leaving room for the co-hosted model and OS overhead.
- The models do not communicate. Each independently serves its own `/v1` API.

---

## 9.3 KubeRay: Reference Path, Not Active

KubeRay is fully installed on the cluster (`kuberay-system` namespace, operator pod `Running`), but it is not routing any live inference traffic.

**What it does on this cluster:** Sits ready for the tensor-parallel deployment path documented in Chapters 5–6.

**When to activate it:** When a project requires serving one model that cannot fit in a single Spark's 128GB — for example:
- Qwen3-235B-A22B-NVFP4
- Nemotron-3-Super-120B
- Any model requiring more than ~100GB of GPU memory

In that case, delete the per-model Deployments from `core-services` to free both GPUs, then deploy the `RayCluster` manifest from Chapter 5 with the large model as the `--model` flag in the head pod command.

---

## 9.4 Repository Layout vs Cluster Layout

| What | Where in repo | Where in cluster |
|------|--------------|-----------------|
| Book chapters / docs | `books/from-box-to-cluster/` | Reference only — deployed via `kubectl apply` |
| Setup automation script | `books/from-box-to-cluster/script.sh` | Run once per fresh cluster setup |
| Model inference config | Chapter 6 manifests | `core-services` namespace (live) |
| Routing layer config | Chapter 7 manifests | `aibrix-system` namespace |
| Monitoring config | Chapter 8 manifests | `monitoring` namespace |
| Research artifacts | `research/` | Not in cluster — local files on Spark 1 |

---

## 9.5 Management Model

The cluster is managed manually from Spark 1 using `kubectl` and `helm`. There is no GitOps operator (ArgoCD, Flux) currently deployed. Changes are applied by running commands directly on Spark 1 after SSH login.

This keeps operational complexity low for a 2-node research cluster. For a future production deployment, GitOps would be the recommended next step.

**Common management commands:**

```bash
# Check what is running
kubectl get pods -A | grep -v Running | grep -v Completed

# Apply a manifest change
kubectl apply -f updated-deployment.yaml

# Scale a model down (free its GPU for another workload)
kubectl scale deployment gemma-2b -n core-services --replicas=0

# Roll out a new model image
kubectl set image deployment/qwen-3b vllm=nvcr.io/nvidia/vllm:25.09-py3 -n core-services

# Force a model pod restart (pick up new HF weights)
kubectl rollout restart deployment/falcon-3b -n core-services
```

---

## Summary

| Layer | What runs | Where |
|-------|-----------|-------|
| Hardware | 2× DGX Spark, QSFP interconnect | Physical |
| OS + CUDA | DGX OS, Ubuntu 24.04.4, CUDA 13.0 | Both Sparks |
| Kubernetes | k3s v1.35.5, Flannel CNI | Both Sparks |
| GPU management | NVIDIA GPU Operator | `gpu-operator` |
| Active inference | 4 independent vLLM processes | `core-services` |
| Routing | AIBrix v0.6.0 | `aibrix-system` |
| Large-model path | KubeRay (installed, standby) | `kuberay-system` |
| Monitoring | Prometheus + Grafana | `monitoring` |

---

*This completes the cluster setup guide. See the Back Matter for command cheatsheet and troubleshooting index.*
