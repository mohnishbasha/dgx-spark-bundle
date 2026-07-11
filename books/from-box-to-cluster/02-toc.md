# Table of Contents

---

**Front Matter**

- [Cover](00-cover.md)
- [Preface](01-preface.md)
- [Table of Contents](02-toc.md)

---

**Part I — Node Setup**

| Chapter | Title | Page |
|---------|-------|------|
| 1 | [Introduction — What You Are Building](#chapter-1) | 1 |
| 2 | [Hardware Setup and First Boot](#chapter-2) | 7 |
| 3 | [CUDA and System Updates](#chapter-3) | 21 |
| 4 | [Kubernetes Cluster with k3s](#chapter-4) | 29 |

**Part II — Model Serving**

| Chapter | Title | Page |
|---------|-------|------|
| 5 | [KubeRay for Distributed AI (Reference Path)](#chapter-5) | 45 |
| 6 | [vLLM Inference Engine — Per-Model and Tensor-Parallel](#chapter-6) | 61 |
| 7 | [AIBrix AI Gateway](#chapter-7) | 77 |
| 8 | [Cluster Overview and Monitoring](#chapter-8) | 91 |
| 9 | [System Architecture Reference](#chapter-9) | 107 |

---

**Back Matter**

- [Quick Reference Command Cheatsheet](#quick-reference)
- [Troubleshooting Index](#troubleshooting)
- [About the Authors](#about-the-authors)

---

## Quick Navigation

### Part I — Node Setup

**Chapter 1 — Introduction**
- What the DGX Spark Bundle is
- Cluster architecture overview
- Software stack diagram
- Namespaces and workload layout
- Automated setup script

**Chapter 2 — Hardware Setup and First Boot**
- Hardware specifications
- Physical connections
- First-boot wizard walkthrough
- Static IP assignment
- iptables persistent rules
- SSH configuration
- Docker cgroup configuration

**Chapter 3 — CUDA and System Updates**
- DGX Dashboard update method
- Terminal update method
- Verifying installed versions
- Updating both nodes

**Chapter 4 — Kubernetes with k3s**
- k3s architecture (master + worker)
- Installing k3s on Spark 1
- Joining Spark 2 as worker
- Installing Helm
- NVIDIA GPU Operator
- Namespace structure

### Part II — Model Serving

**Chapter 5 — KubeRay**
- What KubeRay does
- ARM64 architecture constraint
- Installing the KubeRay operator
- NGC registry authentication
- Cross-node network validation
- Deploying a RayCluster
- Troubleshooting worker failures

**Chapter 6 — vLLM**
- vLLM feature overview
- Tensor parallelism architecture
- HuggingFace token Kubernetes secret
- vLLM deployment via RayCluster
- Startup time expectations
- Verification and API testing
- Serving Kubernetes services

**Chapter 7 — AIBrix**
- What AIBrix provides
- Architecture position in the stack
- Installing dependencies
- Installing AIBrix core
- Verifying components
- Registering a model endpoint
- Namespace integration pattern

**Chapter 8 — Cluster Overview and Monitoring**
- Full cluster specifications
- Node information
- Workload distribution (DaemonSets, Deployments, StatefulSets)
- Monitoring stack installation
- Accessing Grafana
- GPU metrics with DCGM Exporter
- Future architecture roadmap
