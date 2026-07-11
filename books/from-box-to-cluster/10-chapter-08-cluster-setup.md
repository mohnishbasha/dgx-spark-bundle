# Chapter 8 — Cluster Overview and Monitoring

## Overview

This final chapter covers the complete cluster state at the end of setup: all workloads, their placement across nodes, the monitoring stack installation, GPU metrics, and a look at future architecture improvements. Use this chapter as an ongoing operational reference.

## Prerequisites

- All previous chapters complete
- `kubectl` access from Spark 1

---

## 8.1 Cluster Specifications

| Property | Value |
|----------|-------|
| Nodes | 2 |
| Kubernetes | k3s v1.35.5+k3s1 |
| Container runtime | containerd 2.2.3-k3s1 |
| Architecture | ARM64 (aarch64) |
| GPU | 2× NVIDIA GB10 Blackwell |
| Total GPU memory | 256GB unified |
| Total CPU cores | 40 (20 per Spark) |
| Total system memory | ~256GB |
| Interconnect | ConnectX-7 RDMA via QSFP |
| CNI | Flannel (default k3s) |
| OS | Ubuntu 24.04.4 LTS (DGX OS) |

### Node Summary

```bash
kubectl get nodes -o wide
```

```
NAME         STATUS   ROLES                  IP              CONTAINER-RUNTIME
spark-720e   Ready    control-plane,master   192.168.86.30   containerd://2.2.3-k3s1
spark-7229   Ready    worker                 192.168.86.26   containerd://2.2.3-k3s1
```

---

## 8.2 Full Namespace Structure

```
kube-system          — k3s core: CoreDNS, metrics-server, local-path-provisioner
gpu-operator         — NVIDIA GPU management: container toolkit, device plugin, DCGM
kuberay-system       — KubeRay operator
monitoring           — Prometheus, Grafana, AlertManager
core-services        — vLLM + Ray cluster (primary AI inference)
aibrix-system        — AIBrix AI gateway
envoy-gateway-system — Envoy Gateway (AIBrix dependency)
```

---

## 8.3 Workload Distribution

### DaemonSets (run on every node)

These run on both Spark 1 and Spark 2 automatically:

| DaemonSet | Namespace | Purpose |
|-----------|-----------|---------|
| `gpu-feature-discovery` | gpu-operator | Discovers GPU capabilities and labels nodes |
| `nvidia-container-toolkit-daemonset` | gpu-operator | GPU container runtime on each node |
| `nvidia-dcgm-exporter` | gpu-operator | GPU metrics per node (used by Prometheus) |
| `nvidia-device-plugin-daemonset` | gpu-operator | Makes GPUs available as schedulable resources |
| `nvidia-operator-validator` | gpu-operator | Validates GPU operator health on each node |
| `monitoring-prometheus-node-exporter` | monitoring | CPU, memory, disk metrics per node |

### Deployments (single instance, any node)

| Deployment | Namespace | Purpose |
|------------|-----------|---------|
| `coredns` | kube-system | Cluster DNS resolution |
| `metrics-server` | kube-system | CPU/memory metrics for HPA |
| `local-path-provisioner` | kube-system | Local storage provisioning |
| `gpu-operator` | gpu-operator | GPU operator controller |
| `kuberay-operator` | kuberay-system | Manages Ray cluster lifecycle |
| `monitoring-grafana` | monitoring | Metrics visualization |
| `aibrix-controller-manager` | aibrix-system | AIBrix resource reconciliation |
| `aibrix-gateway-plugins` | aibrix-system | Envoy request routing plugins |
| `aibrix-gpu-optimizer` | aibrix-system | GPU utilization-aware scheduling |
| `aibrix-metadata-service` | aibrix-system | Model endpoint metadata storage |
| `aibrix-redis-master` | aibrix-system | Routing decision cache |

### StatefulSets (persistent state)

| StatefulSet | Namespace | Purpose |
|-------------|-----------|---------|
| `prometheus` | monitoring | Metrics storage (persistent PVC) |
| `alertmanager` | monitoring | Alert routing (persistent PVC) |

### Custom Resources (Ray)

| Resource | Namespace | Purpose |
|----------|-----------|---------|
| `RayCluster/vllm-cluster` | core-services | 2-node Ray cluster for vLLM tensor parallelism |

---

## 8.4 Monitoring Stack

The monitoring stack provides visibility into cluster health, resource usage, and GPU metrics.

### Installation

```bash
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring
```

This single Helm chart installs:
- **Prometheus** — time-series metrics collection and storage
- **Grafana** — visualization and dashboarding
- **AlertManager** — alert routing to email, Slack, PagerDuty, etc.
- **Node Exporter** — system metrics (CPU, memory, disk, network) per node
- **kube-state-metrics** — Kubernetes object-level metrics (pod status, resource requests, etc.)

Monitor installation:

```bash
watch kubectl get pods -n monitoring
# All pods should reach Running within 3–5 minutes
```

---

## 8.5 Accessing Grafana

Grafana is the primary dashboard for cluster visualization.

**Get the admin password:**

```bash
kubectl --namespace monitoring get secrets monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d; echo
```

**Port-forward to your browser:**

```bash
kubectl --namespace monitoring port-forward \
  $(kubectl --namespace monitoring get pod \
    -l "app.kubernetes.io/name=grafana" -o name) \
  3000
```

Open `http://localhost:3000` in your browser. Login: `admin` / (password from above).

### Recommended Dashboards

Import these dashboards from Grafana's public library or browse the pre-installed ones:

| Dashboard | Grafana ID | What it shows |
|-----------|-----------|--------------|
| Kubernetes / Compute Resources / Cluster | 17375 | Overall CPU and memory across the cluster |
| Kubernetes / Compute Resources / Node | 17376 | Per-node CPU, memory, and network breakdown |
| Node Exporter / Nodes | 1860 | Detailed system metrics: disk I/O, network, load |
| NVIDIA DCGM Exporter Dashboard | 12239 | GPU utilization, memory, temperature, power draw |

**To import a dashboard by ID:**

1. In Grafana sidebar, click **Dashboards** → **Import**
2. Enter the ID from the table above
3. Click **Load**, then select the Prometheus data source
4. Click **Import**

The DCGM dashboard (ID 12239) is the most important for GPU cluster monitoring. It shows per-GPU utilization, frame buffer usage, power draw, SM clock frequency, and temperature — one panel per GPU across both Sparks.

---

## 8.6 GPU Metrics

GPU metrics are collected automatically by DCGM Exporter (installed by the GPU Operator) and scraped by Prometheus.

### Available Metrics

| Metric | Description |
|--------|-------------|
| `DCGM_FI_DEV_GPU_UTIL` | GPU compute utilization (%) |
| `DCGM_FI_DEV_MEM_COPY_UTIL` | Memory bandwidth utilization (%) |
| `DCGM_FI_DEV_FB_FREE` | Free GPU frame buffer memory (MiB) |
| `DCGM_FI_DEV_FB_USED` | Used GPU frame buffer memory (MiB) |
| `DCGM_FI_DEV_POWER_USAGE` | GPU power draw (Watts) |
| `DCGM_FI_DEV_SM_CLOCK` | SM (streaming multiprocessor) clock speed |
| `DCGM_FI_DEV_GPU_TEMP` | GPU temperature (°C) |

### Quick GPU Status Check

```bash
# Verify GPUs are visible and labeled in Kubernetes
kubectl get nodes -o json | grep -A2 "nvidia.com/gpu.family"
# Expected on each node: "nvidia.com/gpu.family": "blackwell"

kubectl get nodes -o json | grep '"nvidia.com/gpu":'
# Expected on each node: "nvidia.com/gpu": "1"

kubectl get nodes -o json | grep "rdma.available"
# Expected: "rdma.available": "true"
```

---

## 8.7 Quick Reference Commands

### Cluster Health

```bash
# Check all nodes are Ready
kubectl get nodes

# Check for non-Running pods across all namespaces
kubectl get pods -A | grep -v Running | grep -v Completed

# Resource usage per node
kubectl top nodes

# Resource usage per pod
kubectl top pods -A
```

### Monitoring Access

```bash
# Grafana
kubectl -n monitoring get secret monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d; echo
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80

# Prometheus
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090

# Ray Dashboard
HEAD=$(kubectl get pods -n core-services -l ray.io/node-type=head -o name | head -1)
kubectl port-forward -n core-services $HEAD 8265:8265
```

### Testing vLLM

```bash
HEAD=$(kubectl get pods -n core-services -l ray.io/node-type=head -o name | head -1)

# Check models
kubectl exec -n core-services $HEAD -- \
  curl -s http://localhost:8000/v1/models

# Send a test completion
kubectl exec -n core-services $HEAD -- \
  curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen2.5-7B-Instruct","messages":[{"role":"user","content":"Hello."}],"max_tokens":50}'
```

---

## 8.8 Cross-Node Network Validation

At any point, you can re-validate pod-to-pod networking between the two nodes:

```bash
kubectl run test-spark1 \
  --image=busybox \
  --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"spark-720e"}}}' \
  --command -- sleep 3600

kubectl run test-spark2 \
  --image=busybox \
  --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"spark-7229"}}}' \
  --command -- sleep 3600

kubectl get pods -o wide  # copy the SPARK2_POD_IP

kubectl exec test-spark1 -- ping -c 4 <SPARK2_POD_IP>

kubectl delete pod test-spark1 test-spark2
```

---

## 8.9 Future Architecture Roadmap

The current setup prioritizes simplicity and getting AI workloads running. These improvements are planned:

### k3s → RKE2 Migration

| Aspect | Current (k3s + Flannel) | Future (RKE2 + Cilium) |
|--------|------------------------|------------------------|
| CNI | Flannel (VXLAN) | Cilium (eBPF) |
| RDMA support | Not supported | Full RDMA/RoCE |
| NCCL transport | TCP fallback | RDMA over ConnectX-7 |
| Network policies | Basic | eBPF-based, high performance |
| Observability | Limited | Hubble UI built in |
| Security | Standard | CIS hardening available |

**Impact of RDMA:** Cross-node tensor parallel communication in vLLM currently uses TCP (slower). With RDMA over ConnectX-7, the QSFP cable between the two Sparks becomes a true high-bandwidth GPU interconnect, significantly improving throughput for large models.

### MIG (Multi-Instance GPU) Configuration

For multi-tenant workloads, Blackwell-based GPUs support MIG (Multi-Instance GPU) partitioning — slicing one physical GPU into multiple isolated GPU instances with dedicated compute engines and memory.

> **Production Note: Verify MIG support for GB10 before enabling**
>
> MIG was first introduced on A100 (Ampere) and is supported on H100 (Hopper) and H200. The GB10 in the DGX Spark uses Blackwell architecture — Blackwell does support MIG, but the available MIG profiles are specific to the GB10's memory configuration (128GB LPDDR5X, not HBM3). NVIDIA's documentation for GB10 MIG profiles should be consulted before enabling MIG in production.
>
> Check what MIG profiles are available on your hardware:
> ```bash
> nvidia-smi mig -lgip
> # Lists all GPU Instance Profiles supported by your GPU
> ```

If MIG is supported, it can be enabled via the GPU Operator's MIG manager:

```yaml
mig-configs:
  high-throughput:
  - devices: [0]
    mig-enabled: true
    mig-devices:
      "3g.40gb": 2    # two large slices for vLLM instances
      "1g.10gb": 4    # four small slices for AI agents
```

This enables multiple workloads to share one GPU with hardware-enforced memory and performance isolation. Note that MIG and tensor parallelism are mutually exclusive on the same GPU — you cannot use MIG profiles for per-model isolation while also using that GPU in a tensor-parallel deployment.

### Cilium Service Mesh

Adding Cilium as both CNI and service mesh will:
- Replace Flannel with RDMA/RoCE-capable networking
- Provide eBPF-based network policies with near-zero overhead
- Enable Hubble UI for real-time network observability
- Make both nodes behave as one unified compute fabric

---

## Summary

The complete DGX Spark Bundle cluster is now operational:

| Layer | Component | Status |
|-------|-----------|--------|
| Hardware | 2× DGX Spark (GB10, 128GB each) | Connected via QSFP |
| OS | DGX OS — Ubuntu 24.04.4 LTS | CUDA 13.0 |
| Kubernetes | k3s v1.35.5 — 2 nodes Ready | Flannel CNI |
| GPU | NVIDIA GPU Operator | 2 GPUs visible |
| Distributed | KubeRay + Ray 2.49.2 | Head + Worker across nodes |
| Inference | vLLM 0.10.1.1 | Serving on port 8000 |
| Gateway | AIBrix v0.6.0 | Routing + multi-tenancy |
| Monitoring | Prometheus + Grafana | GPU metrics via DCGM |

You now have a production-grade personal AI supercomputer cluster. The infrastructure is ready for AI agent workloads, fine-tuning experiments, and large model inference.

---

*This completes the cluster setup guide. See the Back Matter for a quick reference cheatsheet and troubleshooting index.*
