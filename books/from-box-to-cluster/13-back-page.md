# Back Matter

---

## Quick Reference — Command Cheatsheet

### Cluster Health

```bash
kubectl get nodes                                    # both nodes Ready?
kubectl get pods -A | grep -v Running               # any non-Running pods?
kubectl top nodes                                    # CPU/memory per node
kubectl top pods -A --sort-by=memory               # top memory consumers
```

### vLLM Testing

```bash
HEAD=$(kubectl get pods -n core-services -l ray.io/node-type=head -o name | head -1)
kubectl exec -n core-services $HEAD -- curl -s http://localhost:8000/v1/models
kubectl logs -n core-services -l ray.io/node-type=head --tail=20
```

### GPU Verification

```bash
nvidia-smi                                           # GPU status (on Spark directly)
kubectl get nodes -o json | grep "nvidia.com/gpu\":"  # GPU count per node
```

### Port Forwards

```bash
# Grafana on :3000
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80

# Prometheus on :9090
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090

# Ray Dashboard on :8265
HEAD=$(kubectl get pods -n core-services -l ray.io/node-type=head -o name | head -1)
kubectl port-forward -n core-services $HEAD 8265:8265
```

### Grafana Password

```bash
kubectl -n monitoring get secret monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d; echo
```

### SSH to Spark 2

```bash
ssh moonlit@192.168.86.26
```

### iptables Recovery (if SSH breaks after k3s restart)

```bash
sudo iptables -F && sudo iptables -X
sudo iptables -P INPUT ACCEPT && sudo iptables -P FORWARD ACCEPT && sudo iptables -P OUTPUT ACCEPT
sudo netfilter-persistent save
```

---

## Troubleshooting Index

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| SSH to Spark 2 times out | iptables rules blocked after k3s restart | Flush iptables — see Chapter 2.8 |
| DNS not resolving | systemd-resolved cache stale | `sudo resolvectl flush-caches && sudo systemctl restart systemd-resolved` |
| GPU not visible in Kubernetes | GPU Operator pods not Running | Check `kubectl get pods -n gpu-operator` |
| Ray worker shows `GPU: 0` | Worker pod not connected to head | Check worker pod logs; verify DNS name used in `--address` flag |
| vLLM pod crashes on pull | x86 image used instead of ARM64 | Use `nvcr.io/nvidia/vllm:25.09-py3` — see Chapter 5.2 |
| Model download fails | HF token missing or invalid | Verify `kubectl get secret hf-token -n core-services` exists |
| "exec format error" in pod | x86 image on ARM64 node | Switch to ARM64-native image |
| KubeRay operator not found | Not pinned to correct node | Reinstall with `--set nodeSelector...` — see Chapter 5.3 |
| AIBrix pods in CrashLoopBackOff | Dependencies not installed first | Apply `aibrix-dependency-v0.6.0.yaml` before `aibrix-core-v0.6.0.yaml` |
| NGC image pull fails | containerd doesn't have NGC credentials | Create `docker-registry` Kubernetes secret — see Chapter 5.4 |
| vLLM re-downloads model on every restart | No persistent model cache volume | Add `hostPath` volume for `~/.cache/huggingface` — see Chapter 6.2 |
| AIBrix returns 503 for a model | Wrong `podSelector` labels in ModelAdapter | Per-model pods use `app: <name>`, not `ray.io/node-type: head` — see Chapter 7.7 |
| NCCL hangs or very slow during tensor parallel | Wrong network interface selected | Set `NCCL_SOCKET_IFNAME=eth0` and `NCCL_DEBUG=INFO` — see Chapter 5.7 |
| `nmcli` sets IP on wrong interface | Multiple active connections (WiFi + Ethernet) | Specify connection name explicitly — see Chapter 2.4 |
| k3s uninstall breaks SSH on Spark 2 | k3s leaves iptables rules blocking port 22 | Flush iptables; see Chapter 4.11 recovery procedure |
| `kubectl get nodes` shows NotReady after reboot | k3s service didn't start automatically | `sudo systemctl start k3s` (Spark 1) or `sudo systemctl start k3s-agent` (Spark 2) |
| GPU Operator stuck in Init for >15 min | NGC image pull timing out | Verify internet access; pre-pull image with `docker pull nvcr.io/nvidia/...` |
| Disk full during model download | NVMe SSD full | Check `df -h /`; clear unused container images with `docker system prune` |

---

## Component Version Reference

| Component | Version Used | How Installed |
|-----------|-------------|--------------|
| DGX OS | Ubuntu 24.04.4 LTS | Pre-installed |
| Kernel | 6.17.0-1018-nvidia | DGX Dashboard / apt |
| CUDA Driver | 580.159.03 | DGX Dashboard / apt |
| CUDA Runtime | 13.0 | DGX Dashboard / apt |
| k3s | v1.35.5+k3s1 | `curl \| sh` |
| containerd | 2.2.3-k3s1 | bundled with k3s |
| Helm | 3.x | `curl \| bash` |
| NVIDIA GPU Operator | v24.9.x (Helm latest at install time) | Helm |
| KubeRay Operator | v1.x (Helm latest at install time) | Helm |
| Ray | 2.49.2 | inside vLLM image |
| vLLM | 0.10.1.1 | inside NGC image |
| NVIDIA vLLM Image | nvcr.io/nvidia/vllm:25.09-py3 | NGC |
| AIBrix | v0.6.0 | kubectl apply (pinned) |
| Envoy Gateway | v1.2.8 | bundled in AIBrix deps |
| Prometheus Stack | kube-prometheus-stack latest at install time | Helm |

> **Production Note:** GPU Operator, KubeRay, and Prometheus are installed via `helm install` without a pinned chart version. If you need to reproduce this exact environment, pin chart versions:
> ```bash
> helm install gpu-operator nvidia/gpu-operator --version <chart-version>
> ```
> Run `helm search repo nvidia/gpu-operator --versions` to see available chart versions.

---

## About the Authors

### Mohinish Shaikh

Mohinish Shaikh is an AI infrastructure engineer and researcher focused on building high-performance AI systems on commodity and specialized hardware. He has worked across distributed systems, model serving infrastructure, and AI-native application design. His work on the DGX Spark Bundle project explores running production AI workloads on personal supercomputer hardware.

GitHub: `github.com/mohinishbasha`
Project: `github.com/mohinishbasha/dgx-spark-bundle`

### Sanwi Sarode

Sanwi Sarode is an AI systems engineer specializing in distributed inference, Kubernetes-native AI infrastructure, and model optimization. Her work spans GPU cluster management, tensor parallelism tuning, and multi-tenant AI platform design. She co-authored this guide based on hands-on experience building and operating the DGX Spark cluster documented in these pages.

GitHub: `github.com/sanwisarode`

---

## Resources and References

**NVIDIA DGX Spark**
- DGX Spark Bundle: `marketplace.nvidia.com/en-us/enterprise/personal-ai-supercomputers/dgx-spark-bundle/`
- NGC Container Registry: `ngc.nvidia.com`
- NVIDIA vLLM Image: `nvcr.io/nvidia/vllm:25.09-py3`

**Kubernetes**
- k3s: `k3s.io`
- Helm: `helm.sh`
- NVIDIA GPU Operator: `github.com/NVIDIA/gpu-operator`

**AI Serving Stack**
- KubeRay: `github.com/ray-project/kuberay`
- Ray: `ray.io`
- vLLM: `github.com/vllm-project/vllm`
- AIBrix: `github.com/vllm-project/aibrix`

**Monitoring**
- Prometheus: `prometheus.io`
- Grafana: `grafana.com`
- kube-prometheus-stack: `github.com/prometheus-community/helm-charts`

**Source Repository**
- `github.com/mohinishbasha/dgx-spark-bundle` — full configuration, scripts, and updates to this guide

---

## License

This ebook is licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**.

You are free to:
- **Share** — copy and redistribute in any medium or format
- **Adapt** — remix, transform, and build upon this material for any purpose, including commercially

Under the following terms:
- **Attribution** — You must give appropriate credit, provide a link to the license, and indicate if changes were made

Full license text: `creativecommons.org/licenses/by/4.0/`

---

*From Box to Cluster*
*First Edition, July 2026*
*Mohinish Shaikh · Sanwi Sarode*
