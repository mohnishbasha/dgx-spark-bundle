# Chapter 7 — AIBrix AI Gateway

## Overview

AIBrix is an open-source infrastructure platform that sits between AI applications and vLLM. It provides request routing, multi-tenant isolation, agent lifecycle management, and GPU-utilization-aware scheduling. This chapter installs AIBrix v0.6.0 and registers vLLM as a model endpoint.

## Prerequisites

- k3s cluster running (Chapter 4)
- vLLM deployed and serving in `core-services` namespace (Chapter 6)
- kubectl access from Spark 1

---

## 7.1 What AIBrix Provides

Without AIBrix, every application that wants to use your vLLM cluster must know its internal Kubernetes service address and manage its own connection logic. AIBrix adds an abstraction layer:

```
AI Applications / Agent Swarms
        │
        ▼
AIBrix Gateway (aibrix-system)
├── Request routing → selects the correct model endpoint
├── Quota enforcement → limits per-namespace resource usage
├── Agent lifecycle → manages agent startup/shutdown
├── GPU optimization → schedules based on GPU utilization
└── Multi-tenancy → isolates workloads across namespaces
        │
        ▼
vLLM API Server (core-services:8000)
        │
        ▼
Ray Cluster → Tensor parallel across both GPUs
```

**Why this matters for real workloads:**
- Multiple applications or teams can share one vLLM instance safely
- Each namespace gets its own quota and routing rules
- Swapping the underlying model does not require updating all application configs
- GPU utilization-aware scheduling prevents one heavy workload from starving others

---

## 7.2 Architecture Position

```
namespace: your-app
└── AI agents call: http://aibrix-gateway.aibrix-system.svc.cluster.local
                            │
                            ▼
                   AIBrix routes to:
                   http://vllm-service.core-services.svc.cluster.local:8000

namespace: another-app
└── AI agents call: same AIBrix endpoint, different quota/isolation
```

Multiple namespaces share the same vLLM instance. AIBrix handles per-namespace routing and isolation without requiring separate model deployments per team.

---

## 7.3 Installation

Installation is a two-step process: first install Envoy Gateway and other dependencies, then install AIBrix core.

### Step 1 — Install Dependencies

```bash
kubectl apply \
  -f https://github.com/vllm-project/aibrix/releases/download/v0.6.0/aibrix-dependency-v0.6.0.yaml \
  --server-side \
  --force-conflicts
```

This installs:
- **Envoy Gateway v1.2.8** — the traffic routing and load-balancing layer
- **Gateway API CRDs** — Kubernetes custom resources for defining routing rules
- **Ray CRDs** — for AIBrix's own Ray cluster management

The `--server-side` and `--force-conflicts` flags are required because the manifest applies large CRD schemas that exceed kubectl's default client-side apply limits.

Wait for dependencies to be ready:

```bash
kubectl get pods -n envoy-gateway-system
# Wait until all pods show Running
```

### Step 2 — Install AIBrix Core

```bash
kubectl apply \
  -f https://github.com/vllm-project/aibrix/releases/download/v0.6.0/aibrix-core-v0.6.0.yaml
```

This creates the `aibrix-system` namespace and deploys all AIBrix components.

---

## 7.4 Verification

```bash
kubectl get pods -n aibrix-system
```

Expected output — all pods `Running`:

```
NAME                                        READY   STATUS    AGE
aibrix-controller-manager-xxxxxxxxx         1/1     Running   Xm
aibrix-gateway-plugins-xxxxxxxxx            1/1     Running   Xm
aibrix-gpu-optimizer-xxxxxxxxx              1/1     Running   Xm
aibrix-kuberay-operator-xxxxxxxxx           1/1     Running   Xm
aibrix-metadata-service-xxxxxxxxx           1/1     Running   Xm
aibrix-redis-master-xxxxxxxxx               1/1     Running   Xm
```

---

## 7.5 AIBrix Components

| Component | Purpose |
|-----------|---------|
| `aibrix-controller-manager` | Watches and reconciles AIBrix custom resources (ModelAdapters, etc.) |
| `aibrix-gateway-plugins` | Envoy plugins that implement request routing and quota enforcement |
| `aibrix-gpu-optimizer` | Tracks GPU utilization and influences scheduling decisions |
| `aibrix-kuberay-operator` | AIBrix's own RayCluster management (complements the KubeRay operator) |
| `aibrix-metadata-service` | Stores model endpoint metadata used by routing decisions |
| `aibrix-redis-master` | Caching layer for routing table lookups and rate limiting state |

---

## 7.6 Custom Resource Definitions

AIBrix adds these CRDs to your Kubernetes cluster:

```bash
kubectl get crd | grep aibrix
```

```
modeladapters.model.aibrix.ai                    — register model endpoints
podautoscalers.autoscaling.aibrix.ai             — AI-aware autoscaling
rayclusterfleets.orchestration.aibrix.ai         — manage Ray cluster fleets
stormservices.orchestration.aibrix.ai            — storm service orchestration
kvcaches.orchestration.aibrix.ai                 — KV cache management
```

The primary CRD you interact with is `ModelAdapter` — it registers a vLLM deployment as an addressable model endpoint.

---

## 7.7 Registering a Model (ModelAdapter)

Once you have decided on a target namespace for your application, register a vLLM deployment as a model endpoint in that namespace. The `podSelector` must match the labels on the actual serving pods — the correct labels differ between the two deployment patterns.

**For the active per-model deployment (independent vLLM pods in `core-services`):**

```bash
kubectl apply -f - <<'EOF'
apiVersion: model.aibrix.ai/v1alpha1
kind: ModelAdapter
metadata:
  name: qwen-3b
  namespace: <your-app-namespace>
spec:
  modelName: Qwen/Qwen2.5-3B-Instruct
  replicas: 1
  podSelector:
    matchLabels:
      app: qwen-3b     # matches the label on the Deployment in core-services
EOF
```

**For the tensor-parallel Ray deployment (when KubeRay is active):**

```bash
kubectl apply -f - <<'EOF'
apiVersion: model.aibrix.ai/v1alpha1
kind: ModelAdapter
metadata:
  name: qwen-7b
  namespace: <your-app-namespace>
spec:
  modelName: Qwen/Qwen2.5-7B-Instruct
  replicas: 1
  podSelector:
    matchLabels:
      ray.io/node-type: head   # matches the Ray head pod label
EOF
```

Replace `<your-app-namespace>` with the namespace where your AI agents run (e.g., `snackonai`).

> **Common Pitfall: Wrong podSelector label for per-model deployments**
>
> The `ray.io/node-type: head` label only exists on pods created by a RayCluster. If you are using the active per-model vLLM deployments (Section 6.2), those pods have the label `app: <model-name>` — not Ray labels. Using the wrong selector causes AIBrix to report no matching backends and return 503 errors.
>
> To confirm the correct labels on your serving pods:
> ```bash
> kubectl get pods -n core-services --show-labels
> # Per-model pods: app=qwen-3b, app=smollm-1b, etc.
> # Ray head pod: ray.io/node-type=head, ray.io/cluster=vllm-cluster
> ```

> **Deferred step:** The exact namespace and model configuration depends on your agent architecture. Configure ModelAdapters once you have defined your application namespace structure.

---

## 7.8 Namespace Integration Pattern

The recommended pattern for isolating multiple applications:

```bash
# Create per-application namespaces
kubectl create namespace app-one
kubectl create namespace app-two

# Register the same vLLM model as an endpoint in each namespace
kubectl apply -f model-adapter-app-one.yaml   # targets app-one namespace
kubectl apply -f model-adapter-app-two.yaml   # targets app-two namespace
```

Each namespace gets its own ModelAdapter pointing to the same underlying vLLM pods. AIBrix enforces isolation — requests from `app-one` cannot see or affect `app-two` traffic.

**Resource quotas per namespace** (optional):

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ai-quota
  namespace: app-one
spec:
  hard:
    requests.nvidia.com/gpu: "0"   # agents don't request GPU directly
    requests.cpu: "4"
    requests.memory: "8Gi"
EOF
```

---

## 7.9 Version Information

| Component | Version |
|-----------|---------|
| AIBrix | v0.6.0 (released March 5, 2026) |
| Envoy Gateway | v1.2.8 |
| Compatible Kubernetes | 1.27+ |
| Compatible vLLM | 0.6+ |

---

## 7.10 Next Steps After AIBrix

With AIBrix installed, the infrastructure layer is complete. The remaining configuration is application-specific:

1. **Define namespaces** for each application or team (e.g., `research-dev`, `research-ops`)
2. **Create ModelAdapters** in each namespace pointing to the appropriate vLLM deployment
3. **Set resource quotas** per namespace to prevent one application from consuming all capacity
4. **Deploy AI agents** in their respective namespaces — they call AIBrix's gateway URL rather than vLLM directly

---

## Summary

At the end of this chapter you have:

- [x] AIBrix v0.6.0 installed with all six components `Running`
- [x] Envoy Gateway installed as the traffic routing layer
- [x] AIBrix CRDs available in the cluster
- [x] Understanding of the ModelAdapter pattern for registering vLLM endpoints

---

*Continue to Chapter 8 for the full cluster overview and monitoring stack setup.*
