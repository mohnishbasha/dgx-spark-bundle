# Chapter 4 — Kubernetes Cluster with k3s

## Overview

This chapter installs k3s — a lightweight Kubernetes distribution — across both DGX Sparks, forming a 2-node cluster. Spark 1 acts as the control plane (master); Spark 2 joins as a worker node. We then install Helm and the NVIDIA GPU Operator to make both GB10 GPUs visible to Kubernetes workloads.

## Prerequisites

- Both Sparks on static IPs (Chapter 2)
- Both Sparks fully updated to CUDA 13.0 (Chapter 3)
- SSH access from Spark 1 to Spark 2
- Docker configured with nvidia runtime on both nodes

---

## 4.1 Architecture

```
Spark 1 — spark-720e (192.168.86.30)
  Role: k3s server
  Runs: API server, etcd, scheduler, controller-manager, kubelet

Spark 2 — spark-7229 (192.168.86.26)
  Role: k3s agent
  Runs: kubelet + containerd only
```

k3s runs Kubernetes control plane components inside a single binary, making it significantly lighter than standard Kubernetes while maintaining full API compatibility. It uses **containerd** as the container runtime (not Docker) and **Flannel** as the CNI by default.

> **Why k3s and not full Kubernetes?** For a 2-node personal cluster, k3s removes operational overhead (separate control-plane processes, complex networking setup, manual certificate management) while giving you the full Kubernetes API. The tradeoff is that Flannel CNI does not support RDMA/RoCE networking — NCCL falls back to TCP for cross-node GPU communication. A future migration to RKE2 + Cilium will add full RDMA support.

> **Architectural Insight: k3s uses SQLite, not etcd**
>
> Standard Kubernetes uses etcd as its distributed key-value store for cluster state. k3s replaces etcd with SQLite for clusters with a single control-plane node (the default for clusters under 5 nodes). This is a deliberate design decision — SQLite requires no additional processes, no quorum management, and no backup configuration.
>
> For a 2-node cluster like this one, SQLite is fine. The control plane state (deployments, services, secrets) is stored on Spark 1's local disk. If Spark 1 loses power during a write, there is a small risk of database corruption — acceptable for a research cluster, not acceptable for production. If you need HA control plane in the future, k3s supports embedded etcd with 3+ server nodes.

---

## 4.2 Install k3s on Spark 1 (Master)

Run on **Spark 1**:

```bash
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="--write-kubeconfig-mode 644 --disable=traefik" \
  sh -
```

**Flags explained:**
- `--write-kubeconfig-mode 644` — makes the kubeconfig file readable by your user without `sudo`
- `--disable=traefik` — disables the default Traefik ingress controller (not needed for this setup)
- We do **not** use `--docker` — k3s runs on containerd natively and the GPU Operator requires containerd

The installation takes 1–2 minutes. When complete, the k3s service starts automatically.

---

## 4.3 Configure kubectl

Set the kubeconfig environment variable so `kubectl` commands work without the full path:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc
```

Verify kubectl is working:

```bash
kubectl get nodes
# Expected: spark-720e   Ready   control-plane,master   ...
```

---

## 4.4 Get the Join Token

k3s generates a unique join token on installation. This token authenticates worker nodes joining the cluster.

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Copy the output — it looks like a long random string. You will need it in the next step.

---

## 4.5 Join Spark 2 as Worker

Run on **Spark 2** (via SSH from Spark 1 or directly):

```bash
curl -sfL https://get.k3s.io | \
  K3S_URL=https://192.168.86.30:6443 \
  K3S_TOKEN=<TOKEN_FROM_SPARK1> \
  sh -
```

Replace `<TOKEN_FROM_SPARK1>` with the token you copied in the previous step.

Spark 2 will install the k3s agent and join the cluster. This takes about 1 minute.

---

## 4.6 Assign Worker Role Label

By default, Spark 2 appears in `kubectl get nodes` with no role. Assign the worker role label:

```bash
kubectl label node spark-7229 node-role.kubernetes.io/worker=worker
```

---

## 4.7 Verify Cluster

```bash
kubectl get nodes
```

Expected output:

```
NAME         STATUS   ROLES                  AGE   VERSION
spark-720e   Ready    control-plane,master   Xm    v1.35.5+k3s1
spark-7229   Ready    worker                 Xm    v1.35.5+k3s1
```

Both nodes must show `Ready` before proceeding.

```bash
# Verify containerd runtime (not Docker)
kubectl get nodes -o wide
# CONTAINER-RUNTIME column should show: containerd://2.2.3-k3s1
```

---

## 4.8 Install Helm

Helm is the package manager for Kubernetes — required for installing the GPU Operator, monitoring stack, and KubeRay in subsequent chapters.

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
# Expected: version.BuildInfo{Version:"v3.x.x", ...}
```

---

## 4.9 NVIDIA GPU Operator

The GPU Operator is an NVIDIA-provided Kubernetes operator that automatically deploys and manages all GPU-related components on each node:

- **NVIDIA Container Toolkit** — allows containers to access GPUs
- **NVIDIA Device Plugin** — exposes GPUs as Kubernetes resources (`nvidia.com/gpu`)
- **DCGM Exporter** — exports GPU metrics to Prometheus
- **GPU Feature Discovery** — labels nodes with GPU capabilities

Install with Helm:

```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

helm install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace
```

Installation takes 2–5 minutes. Monitor pod startup:

```bash
watch kubectl get pods -n gpu-operator
```

All pods should reach `Running` or `Completed` state. There are typically 5–8 pods per node.

### Verifying GPU Visibility

Once the GPU Operator is running, verify that Kubernetes can see and schedule to the GPUs:

```bash
# Check GPU family label
kubectl get nodes -o json | grep -i "nvidia.com/gpu.family"
# Expected: "nvidia.com/gpu.family": "blackwell"  (on both nodes)

# Check GPU count per node
kubectl get nodes -o json | grep '"nvidia.com/gpu":'
# Expected: "nvidia.com/gpu": "1"  (one per node)

# Check RDMA availability
kubectl get nodes -o json | grep "rdma.available"
# Expected: "rdma.available": "true"  (ConnectX-7 is RDMA capable)
```

> **Production Note: GPU Operator startup takes several minutes**
>
> On first install, the GPU Operator must pull and initialize multiple DaemonSet pods on both nodes (container toolkit, device plugin, DCGM exporter, feature discovery, validator). Each of these requires downloading a large image from NGC. On a typical home internet connection, expect 5–15 minutes before all pods reach `Running` state.
>
> The `nvidia-operator-validator` pod runs last and does a self-test. It completes and transitions to `Completed` — that is expected, not a failure.
>
> If any pod is stuck in `Init` or `Pending` for more than 10 minutes:
> ```bash
> kubectl describe pod <pod-name> -n gpu-operator
> # Check the Events section at the bottom for image pull errors or resource issues
> ```

> **Common Pitfall: containerd does not use Docker credentials**
>
> k3s uses containerd as the container runtime, not Docker. The `docker login nvcr.io` you will run in Chapter 5 stores credentials in Docker's config (`~/.docker/config.json`). containerd does not read this file.
>
> For NGC images pulled by containerd (including the vLLM image for Ray pods), you need a Kubernetes image pull secret. Create it now so it is ready when needed in Chapter 5:
> ```bash
> kubectl create secret docker-registry ngc-registry \
>   --docker-server=nvcr.io \
>   --docker-username='$oauthtoken' \
>   --docker-password='<YOUR_NGC_API_KEY>' \
>   -n core-services
> ```
> Chapter 5 shows how to reference this secret in pod manifests.

---

## 4.10 Namespace Structure

Create the namespaces used by the infrastructure layers:

```bash
kubectl create namespace core-services
kubectl create namespace monitoring
```

The full namespace layout for this cluster:

```
kube-system           — k3s core (CoreDNS, metrics-server, local-path-provisioner)
gpu-operator          — NVIDIA GPU management (created by Helm above)
kuberay-system        — KubeRay operator (Chapter 5; reference path for large models)
monitoring            — Prometheus + Grafana (created above)
core-services         — Per-model vLLM deployments (active inference layer)
aibrix-system         — AIBrix gateway (auto-created in Chapter 7)
envoy-gateway-system  — Envoy Gateway (auto-created in Chapter 7)
qqq-data              — Project workload namespace (created on demand)
fine-tune             — Project workload namespace (created on demand)
snackonai             — Project workload namespace (created on demand)
```

Project workload namespaces are created when those workloads are deployed and are not part of the base infrastructure setup.

---

## 4.11 Uninstalling k3s (Recovery Reference)

If you need to reinstall from scratch:

```bash
# On Spark 1 (master)
/usr/local/bin/k3s-uninstall.sh

# On Spark 2 (worker) via SSH
ssh moonlit@192.168.86.26 "/usr/local/bin/k3s-agent-uninstall.sh"
```

> **Warning:** k3s uninstall leaves iptables rules that block SSH on Spark 2. After uninstalling on Spark 2, you need physical access or a console to flush them:
> ```bash
> sudo iptables -F && sudo iptables -X
> sudo iptables -P INPUT ACCEPT
> sudo iptables -P FORWARD ACCEPT
> sudo iptables -P OUTPUT ACCEPT
> ```
> Then re-add the persistent rules from Chapter 2 and re-run `sudo netfilter-persistent save`.

---

## 4.12 Architecture Notes

**CNI: Flannel**
k3s uses Flannel as the default CNI. Flannel provides pod-to-pod networking across nodes using VXLAN encapsulation. It does not support RDMA/RoCE — meaning NCCL (used by vLLM for tensor parallelism) falls back to TCP-based communication for cross-node GPU traffic.

**Future: RKE2 + Cilium**
A planned migration to RKE2 with Cilium CNI will enable full RDMA-aware networking, allowing the ConnectX-7 interconnect to be used for high-speed GPU-to-GPU communication. This will significantly improve tensor parallel throughput for larger models.

**k3s vs full Kubernetes**
k3s runs the API server, scheduler, and controller-manager as goroutines within a single binary rather than separate pods. This is invisible to kubectl users but means the control plane is not visible under `kubectl get pods -n kube-system` — only CoreDNS, metrics-server, and local-path-provisioner appear there.

---

## Summary

At the end of this chapter you have:

- [x] k3s installed on Spark 1 as control plane
- [x] Spark 2 joined as worker node
- [x] `kubectl get nodes` shows both nodes `Ready`
- [x] Helm installed
- [x] NVIDIA GPU Operator installed and running
- [x] Both GB10 GPUs visible as `nvidia.com/gpu` resources in Kubernetes
- [x] `core-services` and `monitoring` namespaces created

---

*Continue to Chapter 5 to install KubeRay and deploy a distributed Ray cluster.*
