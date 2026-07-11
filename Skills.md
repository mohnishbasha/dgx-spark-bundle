# Skills & Technology Reference

Technologies and skills documented in books published from this repository.

## Hardware

| Skill | Context |
|---|---|
| NVIDIA DGX Spark unboxing & first boot | From Box to Cluster, Ch 2 |
| Static IP assignment via NetworkManager (`nmcli`) | From Box to Cluster, Ch 2 |
| QSFP / ConnectX-7 RDMA cluster cabling | From Box to Cluster, Ch 2 |
| Docker cgroup v2 + NVIDIA runtime configuration | From Box to Cluster, Ch 2 |

## System / OS

| Skill | Context |
|---|---|
| DGX Dashboard update workflow | From Box to Cluster, Ch 3 |
| CUDA 13.0 driver update via `apt dist-upgrade` | From Box to Cluster, Ch 3 |
| `iptables` persistence with `netfilter-persistent` | From Box to Cluster, Ch 2 |
| SSH socket-to-service migration (`systemd`) | From Box to Cluster, Ch 2 |

## Kubernetes

| Skill | Context |
|---|---|
| k3s single-binary Kubernetes install | From Box to Cluster, Ch 4 |
| k3s worker node join procedure | From Box to Cluster, Ch 4 |
| NVIDIA GPU Operator (Helm) | From Box to Cluster, Ch 4 |
| Cross-node pod networking validation | From Box to Cluster, Ch 5 |

## AI / Model Serving

| Skill | Context |
|---|---|
| KubeRay operator install + ARM64 image selection | From Box to Cluster, Ch 5 |
| RayCluster deployment YAML | From Box to Cluster, Ch 5 |
| vLLM tensor parallelism across 2 GPUs | From Box to Cluster, Ch 6 |
| vLLM OpenAI-compatible API verification | From Box to Cluster, Ch 6 |
| AIBrix gateway install + ModelAdapter CRD | From Box to Cluster, Ch 7 |

## Observability

| Skill | Context |
|---|---|
| kube-prometheus-stack (Helm) | From Box to Cluster, Ch 8 |
| DCGM Exporter GPU metrics | From Box to Cluster, Ch 8 |
| Grafana port-forward access | From Box to Cluster, Ch 8 |

## Models Validated on DGX Spark Bundle (256 GB)

- Qwen/Qwen2.5-7B-Instruct
- Qwen/Qwen2.5-72B-Instruct
- meta-llama/Llama-3.3-70B-Instruct
- Qwen3-235B-A22B-NVFP4 (quantized)
- Nemotron-3-Super-120B
- Llama 405B (quantized)
