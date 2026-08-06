# From Box to Cluster: Building a Personal AI Supercomputer with NVIDIA DGX Spark Bundle

**Read online:** https://mohnishbasha.github.io/dgx-spark-bundle/books/from-box-to-cluster/

Step-by-step guide to configuring two NVIDIA DGX Spark units into a production AI inference cluster. Covers everything from first boot and static IP assignment through Kubernetes, distributed model serving, and monitoring.

---

## Hardware

- 2× NVIDIA DGX Spark (GB10 Blackwell GPU, 128 GB unified memory each)
- ConnectX-7 RDMA interconnect
- 256 GB combined unified memory

## Software Stack

| Layer | Technology |
|-------|-----------|
| OS | DGX OS (Ubuntu-based) |
| Container runtime | containerd |
| Kubernetes | k3s (master + worker) |
| GPU operator | NVIDIA GPU Operator |
| Distributed AI | KubeRay |
| Inference engine | vLLM (tensor-parallel) |
| AI gateway | AIBrix |
| Monitoring | Prometheus · Grafana · DCGM Exporter |

---

## Table of Contents

### Part I — Node Setup

| Chapter | Title |
|---------|-------|
| 1 | Introduction — What You Are Building |
| 2 | Hardware Setup and First Boot |
| 3 | CUDA and System Updates |
| 4 | Kubernetes Cluster with k3s |

### Part II — Model Serving

| Chapter | Title |
|---------|-------|
| 5 | KubeRay for Distributed AI |
| 6 | vLLM Inference Engine — Per-Model and Tensor-Parallel |
| 7 | AIBrix AI Gateway |
| 8 | Cluster Overview and Monitoring |
| 9 | System Architecture Reference |

### Back Matter

- Quick Reference Command Cheatsheet
- Troubleshooting Index
- About the Authors

---

## Source Files

```
from-box-to-cluster/
├── 00-cover.md
├── 01-preface.md
├── 02-toc.md
├── 03-chapter-01-introduction.md
├── 04-chapter-02-hardware-setup.md
├── 05-chapter-03-cuda-updates.md
├── 06-chapter-04-k3s-setup.md
├── 07-chapter-05-kuberay-setup.md
├── 08-chapter-06-vllm-setup.md        (vLLM inference)
├── 09-chapter-07-aibrix-setup.md
├── 10-chapter-08-cluster-setup.md
├── 12-chapter-09-system-architecture.md
├── index.html                          # Single-page ebook
├── styles.css
├── build.sh                            # PDF/HTML artifact generator
└── dist/                               # Generated artifacts
```

---

## Authors

- **Mohinish Shaikh** — [GitHub](https://github.com/mohnishbasha) · [LinkedIn](https://www.linkedin.com/in/mohinishbasha/)
- **Sanwi Sarode** — [GitHub](https://github.com/sanwisarode) · [LinkedIn](https://www.linkedin.com/in/sanwi-sarode-785b0b282/)

## License

[Creative Commons Attribution 4.0 International (CC BY 4.0)](../../LICENSE)
