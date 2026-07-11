---
title: "From Box to Cluster"
subtitle: "Building a Personal AI Supercomputer with NVIDIA DGX Spark Bundle"
authors:
  - "Mohinish Shaikh"
  - "Sanwi Sarode"
edition: "First Edition"
date: "July 2026"
version: "1.0.0"
publisher: "Serverless Ventures LLC"
---

# From Box to Cluster

## Building a Personal AI Supercomputer with NVIDIA DGX Spark Bundle

---

**Authors**

Mohinish Shaikh
Sanwi Sarode

---

**First Edition · July 2026**
**Version 1.0.0**

---

*From bare hardware to a production-grade AI inference cluster running large language models across two NVIDIA DGX Spark units — documented step by step.*

---

> "The best time to build your own AI supercomputer was last year. The second best time is today."

---

**Published by Serverless Ventures LLC**
`www.serverlessvc.com`

---

© 2026 Mohinish Shaikh, Sanwi Sarode. All rights reserved.

No part of this publication may be reproduced, distributed, or transmitted in any form or by any means without the prior written permission of the authors.

The information in this book is provided on an "as is" basis. The authors make no guarantees as to the completeness or accuracy of the contents and specifically disclaim any implied warranties or fitness for any particular purpose.

NVIDIA, DGX Spark, CUDA, and related marks are trademarks of NVIDIA Corporation. Kubernetes, Ray, vLLM, and other product names are trademarks of their respective owners.

---

**Contact**
For questions, corrections, or contributions, open an issue at:
`https://github.com/mohinishbasha/dgx-spark-bundle`


---

# Preface

## Why We Wrote This Book

In early 2026, NVIDIA released the DGX Spark — a personal AI supercomputer the size of a Mac mini, packing a Grace Blackwell GB10 GPU with 128GB of unified memory into a single quiet desktop unit. For the first time, running frontier-scale AI workloads from a home lab or a startup office became genuinely practical.

Setting up two of them as a production cluster involved weeks of hard-won lessons: first-boot quirks, ARM64 compatibility landmines, networking configurations that broke SSH, container images that silently ran on the wrong architecture, and tensor parallelism tuning that only worked after we understood the interplay between NCCL, Ray, and the k3s networking layer. None of this was fully documented in a single place.

This book is the documentation we wish we had when we started.

## What This Book Covers

We walk through configuring a 2-node DGX Spark cluster from physical hardware to a production-grade AI inference platform serving large language models over an OpenAI-compatible API. Specifically, we cover:

- **Hardware setup** — physical connections, first-boot wizard, static IP assignment, SSH, Docker
- **System updates** — OS, CUDA 13.0, and driver updates via the DGX Dashboard
- **Kubernetes** — k3s installation, GPU Operator, Helm, namespace architecture
- **Distributed inference** — KubeRay operator, cross-node Ray cluster, ARM64-specific gotchas
- **vLLM** — tensor parallelism across both nodes, model serving, HuggingFace token management
- **AIBrix** — AI gateway layer for request routing, multi-tenancy, and agent lifecycle management
- **Monitoring** — Prometheus, Grafana, GPU metrics via DCGM Exporter

Each chapter maps directly to a configuration step, presented in the exact order you should execute them.

## Who This Book Is For

This book assumes you:

- Are comfortable with a Linux terminal
- Have basic familiarity with Kubernetes concepts (pods, namespaces, deployments)
- Have purchased or are evaluating the NVIDIA DGX Spark Bundle (two DGX Spark units)
- Want to run real AI workloads — not toy demos — on your own hardware

You do not need to be a DevOps engineer or CUDA expert. We explain every decision and every command, including why certain approaches were tried and abandoned.

## A Note on Platform-Specific Details

The DGX Spark runs on ARM64 (Grace CPU). This matters more than you might expect. Many popular container images — including the standard Ray image — are x86 only and will silently fail or throw cryptic errors on ARM64. We call these out explicitly throughout the book and always provide the correct ARM64-native alternative.

## How to Use This Book

Read the chapters in order on first setup. Each chapter lists its prerequisites clearly so you know exactly what must be in place before proceeding. After initial setup, each chapter also serves as a standalone reference for that component.

Command blocks are copy-paste ready. Placeholders are shown in `<ANGLE_BRACKETS>` — replace them with your actual values before running.

## Acknowledgments

We owe thanks to the teams behind k3s, KubeRay, vLLM, and AIBrix — all open source projects that made this infrastructure possible. Special thanks to the NVIDIA DGX documentation team whose dashboard tooling made first-boot surprisingly smooth.

---

*Mohinish Shaikh*
*Sanwi Sarode*
*July 2026*


---

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


---

# Chapter 1 — Introduction: What You Are Building

## The DGX Spark Bundle

The NVIDIA DGX Spark Bundle is two DGX Spark personal AI supercomputers sold together with everything needed to link them into a single distributed cluster. Each Spark is a self-contained machine with a Grace Blackwell GB10 GPU, 128GB of unified CPU-GPU memory, and a 20-core ARM64 CPU — all in a compact desktop form factor.

When you connect two Sparks over QSFP and configure them as a cluster, you get:

| Resource | Per Spark | Combined |
|----------|-----------|----------|
| GPU | 1× NVIDIA GB10 Blackwell | 2× GPUs |
| GPU Memory | 128GB unified | 256GB unified |
| CPU Cores | 20 (ARM64) | 40 cores |
| Interconnect | — | ConnectX-7 RDMA (QSFP) |
| OS | DGX OS (Ubuntu 24.04.4 LTS) | — |

This combined system can load and serve language models that would not fit on either GPU alone — models with tens or hundreds of billions of parameters — by splitting weights across both GPUs using tensor parallelism.

> **Architectural Insight: What "unified memory" actually means**
>
> On conventional GPU servers, the CPU has its own DRAM and the GPU has its own GDDR or HBM. Moving data between them costs a PCIe transfer — typically 16–32 GB/s and a round-trip latency measured in microseconds.
>
> On the DGX Spark, the Grace CPU and Blackwell GPU are connected via NVLink-C2C — a chip-to-chip interconnect embedded in the same module. Both processors share a single pool of LPDDR5X memory at up to 900 GB/s. There is no PCIe bus and no copy penalty. A tensor allocated in CPU memory is immediately visible to the GPU at the same address, at full bandwidth.
>
> This is why 128GB is the "GPU memory" — it is the total system memory, and all of it is available to GPU workloads. For LLM inference, this means you can load a 70B parameter model in fp16 (~140GB) across two Sparks without the weight-loading bottleneck that limits conventional GPU clusters.
>
> The ConnectX-7 QSFP cable is a separate interconnect for *cross-node* communication between the two Spark units. It is not NVLink — it is an RDMA-capable network interface used by NCCL for tensor parallel all-reduce operations.

## What You Will Have at the End

By the time you finish this book, you will have:

1. **Two DGX Spark nodes** connected physically and configured with static IPs, SSH, and Docker
2. **A 2-node k3s Kubernetes cluster** with Spark 1 as control plane and Spark 2 as worker
3. **NVIDIA GPU Operator** making both GB10 GPUs visible to Kubernetes
4. **KubeRay operator** installed as a reference path for large-model tensor parallelism
5. **vLLM** deployable in two patterns — per-model independent processes (active) or tensor-parallel across both GPUs (reference)
6. **AIBrix** routing AI agent requests to vLLM with multi-tenant isolation
7. **Prometheus + Grafana** monitoring the full stack including GPU metrics

The result is a production-ready AI inference platform that you own, control, and can extend.

## Two Deployment Patterns

The cluster supports two distinct ways to serve models with vLLM. Understanding the difference upfront will help you follow Chapters 5–6 with the right mental model.

| Pattern | When to use | How it works |
|---------|------------|-------------|
| **Independent per-model** (active) | Multiple small models, comparison/ensembling, research | Each model runs as its own vLLM process in `core-services`. Spark 1 and Spark 2 each host 1–2 models independently. No cross-node communication needed. |
| **Tensor-parallel via KubeRay** (reference) | One large model that exceeds 128GB | vLLM splits weight tensors across both GPUs using Ray. Both Sparks collaborate on every inference call. Used for models like Qwen3-235B or Llama 405B. |

**The active deployment** uses 4 independent small models:

```
Spark 1 (192.168.86.30)          Spark 2 (192.168.86.26)
├── qwen-3b  (vLLM process)       ├── gemma-2b  (vLLM process)
└── smollm-1b (vLLM process)      └── falcon-3b (vLLM process)
```

Each model is independently addressable. No Ray cluster is involved. This is simpler, more resilient, and the right choice for running several small models side by side.

**The tensor-parallel path** (Chapters 5–6) is documented as the setup to reach for when a single model's weights exceed one Spark's 128GB unified memory. KubeRay is installed on the cluster but is not the currently active inference route.

## Software Stack

The full software stack, from hardware up:

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Applications / Agents                  │
├─────────────────────────────────────────────────────────────┤
│              AIBrix v0.6.0  (aibrix-system)                  │
│         Request routing · Multi-tenancy · GPU scheduling      │
├─────────────────────────────────────────────────────────────┤
│     vLLM 0.10.1.1  (core-services namespace)                 │
│      OpenAI-compatible API · Tensor Parallel across 2 GPUs   │
├─────────────────────────────────────────────────────────────┤
│         KubeRay  (kuberay-system)                            │
│         Ray 2.49.2 · 2-node distributed cluster              │
├─────────────────────────────────────────────────────────────┤
│         k3s v1.35.5  ·  Flannel CNI                         │
│         Kubernetes control plane + workload scheduler         │
├─────────────────────────────────────────────────────────────┤
│     NVIDIA GPU Operator  (gpu-operator namespace)            │
│   Container Toolkit · Device Plugin · DCGM Exporter          │
├─────────────────────────────────────────────────────────────┤
│     DGX OS (Ubuntu 24.04.4 LTS)  ·  Kernel 6.17             │
│         CUDA 13.0  ·  Driver 580.159.03                      │
├─────────────────────────────────────────────────────────────┤
│   Spark 1 (GB10, 128GB)  ←QSFP→  Spark 2 (GB10, 128GB)     │
│              ConnectX-7 RDMA interconnect                     │
└─────────────────────────────────────────────────────────────┘
```

## Cluster Architecture

<div align="center">
  <img src="assets/cluster-architecture.svg" alt="DGX Spark Bundle 2-Node Cluster Architecture" width="100%"/>
</div>

The diagram above shows the complete cluster: both Spark nodes, their hardware and software layers, the QSFP ConnectX-7 RDMA interconnect between them, and their connection to the home network. The color coding maps to the software stack: purple = hardware, green = OS/CUDA, indigo = Kubernetes, amber = GPU Operator, pink = active workloads.

## Kubernetes Namespace Layout

The cluster is organized into purpose-specific namespaces:

| Namespace | Purpose |
|-----------|---------|
| `kube-system` | k3s core — CoreDNS, metrics-server |
| `gpu-operator` | NVIDIA GPU management and visibility |
| `kuberay-system` | KubeRay operator (installed; reference path for large models) |
| `monitoring` | Prometheus + Grafana + AlertManager |
| `core-services` | Per-model vLLM deployments (primary active inference) |
| `aibrix-system` | AIBrix request routing and agent lifecycle |
| `envoy-gateway-system` | Envoy Gateway (AIBrix traffic layer) |
| `qqq-data` | Project workload (offline pipeline) |
| `fine-tune` | Project workload (real-time pipeline) |
| `snackonai` | Project workload (research agent pipeline) |

## Models You Can Serve

With 256GB of combined unified memory, the cluster can handle:

| Model | Parameters | GPU Memory Required | Notes |
|-------|-----------|---------------------|-------|
| Qwen2.5-7B-Instruct | 7B | ~14GB (bf16) | Default setup in this book; fits on one Spark |
| Qwen2.5-72B-Instruct | 72B | ~144GB (bf16) | Requires tensor parallelism across both Sparks |
| Qwen3-235B-A22B-NVFP4 | 235B (MoE) | ~120GB (NVFP4) | MoE architecture — active params ~22B per token |
| Nemotron-3-Super-120B | 120B | ~60–80GB (quantized) | Requires AWQ or int8 quantization |
| Llama 3.3 70B Instruct | 70B | ~140GB (bf16) | Fits across both Sparks with headroom |

> **Deep Dive: How quantization affects memory**
>
> Model memory = (parameter count) × (bytes per parameter).
> - float32 (fp32): 4 bytes/param → 7B model = 28GB
> - bfloat16 (bf16): 2 bytes/param → 7B model = 14GB
> - int8: 1 byte/param → 7B model = 7GB
> - NVFP4 (NVIDIA 4-bit): 0.5 bytes/param → 7B model = 3.5GB
>
> NVFP4 is NVIDIA's native 4-bit format for Blackwell. It is not the same as the community AWQ or GPTQ formats. NVFP4 models must be pre-quantized — vLLM supports loading them with `--quantization nvfp4` but cannot quantize on the fly at load time.
>
> For Mixture-of-Experts (MoE) models like Qwen3-235B, the stated 235B total parameters represent all expert weights. Only the "active" parameters (~22B) are computed per forward pass, which is why these models can run faster than dense 235B models despite the large memory footprint.

## Automated Setup

Once you have done this manually once, you can reproduce the full cluster from scratch using the automation script:

```bash
git clone https://github.com/mohinishbasha/dgx-spark-bundle.git
cd dgx-spark-bundle
bash books/from-box-to-cluster/script.sh \
  --spark1-ip 192.168.86.30 \
  --spark2-ip 192.168.86.26 \
  --spark2-user moonlit \
  --spark1-hostname spark-720e \
  --spark2-hostname spark-7229 \
  --hf-token <YOUR_HUGGINGFACE_TOKEN>
```

The script is idempotent — safe to re-run if a step fails partway through.

## Chapter Sequence

Complete these chapters in order:

| Order | Chapter | Time Estimate |
|-------|---------|---------------|
| 1 | This chapter | — |
| 2 | Hardware Setup and First Boot | 60–90 min |
| 3 | CUDA and System Updates | 30–60 min |
| 4 | Kubernetes with k3s | 20–30 min |
| 5 | KubeRay | 15–20 min |
| 6 | vLLM | 30–60 min (includes model download) |
| 7 | AIBrix | 10–15 min |
| 8 | Cluster Overview and Monitoring | 20–30 min |

**Total estimated time:** 3–5 hours for a complete setup on two fresh units.

---

*Continue to Chapter 2 to begin with hardware setup and first boot.*


---

# Chapter 2 — Hardware Setup and First Boot

## Overview

This chapter covers unboxing, physical connection, first-boot configuration, network setup, and Docker configuration for both DGX Spark units. Complete this chapter before anything else — later steps assume both nodes are on static IPs with SSH working between them.

## Prerequisites

- Two NVIDIA DGX Spark units (unpacked)
- One QSFP cable (included in DGX Spark Bundle)
- A monitor with HDMI input
- A USB-C hub (the DGX Spark has USB-C ports only)
- A keyboard and mouse (via USB-C hub)
- A network switch or router with available Ethernet ports

---

## 2.1 Hardware Specifications

Each DGX Spark unit:

| Component | Specification |
|-----------|---------------|
| GPU | NVIDIA GB10 Blackwell (Grace Blackwell Superchip) |
| GPU Memory | 128GB unified (shared with CPU) |
| CPU | 20-core ARM64 (Grace CPU) |
| System Memory | 128GB unified (same pool as GPU) |
| Storage | 1TB NVMe SSD |
| Network | ConnectX-7 (QSFP, RDMA-capable) + 1GbE RJ45 |
| OS | DGX OS (Ubuntu 24.04.4 LTS) |
| Kernel | 6.17.0-1018-nvidia |

Combined across two units: **2× GB10 GPUs, 256GB unified memory, 40 CPU cores.**

> **Production Note: Storage capacity matters for model weights**
>
> Each DGX Spark includes a 1TB NVMe SSD. Large language models consume significant disk space:
> - Qwen2.5-7B in bf16: ~14GB
> - Llama 3.3 70B in bf16: ~140GB
> - Qwen3-235B in NVFP4: ~120GB
>
> With a 1TB drive shared between the OS (~30GB), container images (~50GB), and multiple model weight downloads, disk pressure is a real concern. Check available space before starting large model downloads:
> ```bash
> df -h /
> ```
> Models are cached by HuggingFace Hub in `~/.cache/huggingface/hub/`. For persistent model caching across pod restarts, configure a Kubernetes PersistentVolumeClaim backed by the local NVMe — covered in Chapter 6.

---

## 2.2 Physical Setup

### Connecting the Hardware

1. **Power:** Connect both Sparks to power outlets. They power on automatically when plugged in — no power button press needed.

2. **Display:** Connect a monitor to **Spark 1 only** via HDMI. Spark 2 will be managed headlessly via SSH after initial setup.

3. **Input:** Connect a USB-C hub to Spark 1 and attach a keyboard and mouse through the hub.

   > **Note:** The DGX Spark has USB-C ports only. A USB-C to USB-A hub is required for standard keyboards and mice.

4. **Ethernet:** Connect both Sparks to your network via Ethernet for internet access during software download.

5. **QSFP interconnect:** Connect the QSFP cable between the ConnectX-7 ports on each unit. This cable is used for high-speed RDMA communication between the two GPUs.

### Cable Diagram

```
         Spark 1                    Spark 2
   ┌──────────────┐           ┌──────────────┐
   │              │           │              │
   │  HDMI ───────┤Monitor    │              │
   │  USB-C ──────┤Hub──KBD   │              │
   │  Ethernet ───┤Router     │ Ethernet ────┤Router
   │  QSFP ───────┼───────────┼── QSFP       │
   │              │           │              │
   └──────────────┘           └──────────────┘
```

---

## 2.3 First Boot — Setup Wizard

On first power-on, DGX OS launches an interactive setup wizard on Spark 1's display. Step through it:

1. **Select keyboard layout** — choose your locale
2. **Accept the license agreement**
3. **Create your user account** — choose a username and password. In this guide we use `moonlit` as the username for both units.
4. **Network connection** — connect to WiFi or skip (Ethernet is recommended for the software download step)
5. **Software image download** — the system downloads and installs the complete DGX software image automatically

> **Warning:** Do **not** power off or unplug during the software download step. The download cannot be resumed if interrupted. Expect this to take 15–45 minutes depending on your internet connection.

After the wizard completes, Spark 1 will reboot into the full DGX OS desktop.

### Spark 2 First Boot

Spark 2 boots independently. If you have a second monitor, repeat the wizard there. Alternatively, the wizard can be completed on Spark 2 later via SSH port forwarding — but the simplest path is to have a second monitor available temporarily.

After creating the user account with the **same username** on Spark 2 (e.g., `moonlit`), you can manage it entirely from Spark 1 via SSH.

---

## 2.4 Network Configuration

### Static IP Assignment

Static IPs prevent the cluster from breaking between sessions when DHCP assigns different addresses. Configure both Sparks with fixed IPs before proceeding to any Kubernetes setup.

**Assigned IPs for this guide:**
- Spark 1 (master): `192.168.86.30`
- Spark 2 (worker): `192.168.86.26`
- Gateway: `192.168.86.1` (your router)

Adjust these to match your network. The `/24` subnet is assumed throughout this book.

**On Spark 1:**

```bash
sudo nmcli con mod "$(nmcli -g NAME con show --active | head -1)" \
  ipv4.addresses 192.168.86.30/24 \
  ipv4.gateway 192.168.86.1 \
  ipv4.dns 8.8.8.8 \
  ipv4.method manual
sudo nmcli con up "$(nmcli -g NAME con show --active | head -1)"
```

**On Spark 2** (replace with Spark 2's IP):

```bash
sudo nmcli con mod "$(nmcli -g NAME con show --active | head -1)" \
  ipv4.addresses 192.168.86.26/24 \
  ipv4.gateway 192.168.86.1 \
  ipv4.dns 8.8.8.8 \
  ipv4.method manual
sudo nmcli con up "$(nmcli -g NAME con show --active | head -1)"
```

After running these commands, the active connection is reconfigured with the new static IP. The change takes effect immediately — no reboot needed.

> **Common Pitfall: Multiple active connections**
>
> The command above grabs the first active connection name. If the DGX Spark has both Ethernet and WiFi active simultaneously, `head -1` may target the wrong interface.
>
> To be precise, list connections first and use the Ethernet interface name explicitly:
> ```bash
> nmcli con show --active
> # Look for the connection on your Ethernet interface (e.g., "Wired connection 1")
> sudo nmcli con mod "Wired connection 1" \
>   ipv4.addresses 192.168.86.30/24 \
>   ipv4.gateway 192.168.86.1 \
>   ipv4.dns 8.8.8.8 \
>   ipv4.method manual
> sudo nmcli con up "Wired connection 1"
> ```
>
> After the static IP is set, verify it took effect:
> ```bash
> ip addr show | grep "192.168.86"
> # Should show your assigned address on the Ethernet interface
> ```

### iptables Persistent Rules

k3s modifies iptables rules during installation and operation. Without persistent rules, your router subnet traffic (including SSH) can be inadvertently blocked after a k3s restart or reboot.

Add these rules on **both Sparks** to prevent this:

```bash
sudo iptables -I INPUT -s 192.168.86.0/24 -j ACCEPT
sudo iptables -I FORWARD -s 192.168.86.0/24 -j ACCEPT
sudo apt install iptables-persistent -y
sudo netfilter-persistent save
```

This saves the rules to survive reboots.

---

## 2.5 SSH Setup

Spark 2 is managed headlessly from Spark 1 via SSH. Enable SSH properly on Spark 2.

**On Spark 2:**

```bash
sudo systemctl stop ssh.socket
sudo systemctl disable ssh.socket
sudo systemctl enable ssh
sudo systemctl start ssh
```

> **Deep Dive: Why switch from ssh.socket to ssh?**
>
> DGX OS ships SSH configured as a socket-activated service (`ssh.socket`). In this mode, systemd listens on port 22 and spawns the SSH daemon only when a connection arrives — it does not keep `sshd` running continuously.
>
> In a cluster environment, this has two failure modes:
> 1. After k3s modifies iptables, the socket activation can race with the firewall rules, causing intermittent SSH failures that are hard to diagnose.
> 2. Some automation tools and cluster health checks expect a persistent SSH daemon, not an on-demand one.
>
> Switching to a persistent `ssh` service (`sshd` always running) eliminates this race condition. The tradeoff is a small increase in idle memory usage — negligible on a 128GB system.

Enable password authentication. Edit `/etc/ssh/sshd_config` on Spark 2:

```
PasswordAuthentication yes
```

Then restart SSH:

```bash
sudo systemctl restart ssh
```

**From Spark 1**, verify the connection:

```bash
ssh moonlit@192.168.86.26
```

Accept the host key fingerprint when prompted. You should reach a shell on Spark 2.

### SSH Key-Based Authentication (Recommended)

After verifying password auth works, set up key-based auth from Spark 1 to Spark 2 for convenience:

```bash
# On Spark 1 — generate key if you don't have one
ssh-keygen -t ed25519 -C "spark1-to-spark2"

# Copy key to Spark 2
ssh-copy-id moonlit@192.168.86.26
```

---

## 2.6 Baseline System Snapshot

Before changing anything further, capture a baseline of the system state on both Sparks. This is useful for debugging later if something goes wrong:

```bash
# GPU baseline
nvidia-smi

# Kernel and OS
uname -r && cat /etc/os-release | grep PRETTY_NAME

# Disk space available for model weights
df -h /

# Current network configuration
ip addr show && ip route show

# Docker status
docker info | grep -E "Runtimes|Cgroup"
```

Save this output — it becomes your reference point if a driver update or configuration change causes unexpected behavior.

---

## 2.7 DNS Troubleshooting

If DNS stops resolving after a network reconfiguration:

```bash
sudo resolvectl flush-caches
sudo systemctl restart systemd-resolved
```

Verify resolution works:

```bash
nslookup google.com
```

---

## 2.8 iptables Troubleshooting

If SSH becomes blocked after a k3s restart (symptom: `ssh moonlit@192.168.86.26` times out):

```bash
sudo iptables -F
sudo iptables -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
```

This flushes all iptables rules. Then re-save the persistent rules:

```bash
sudo netfilter-persistent save
```

---

## 2.9 Docker Configuration

Docker needs two configuration changes for proper cgroup v2 compatibility with the NVIDIA container runtime:

1. **Default cgroup namespace mode** — must be `host` for GPU containers to work correctly
2. **Default runtime** — set to `nvidia` so all containers use the GPU runtime by default

Run this on **both Sparks**:

```bash
sudo python3 -c "
import json, os
path = '/etc/docker/daemon.json'
d = json.load(open(path)) if os.path.exists(path) else {}
d['default-cgroupns-mode'] = 'host'
d['default-runtime'] = 'nvidia'
d['runtimes'] = {'nvidia': {'path': 'nvidia-container-runtime', 'args': []}}
json.dump(d, open(path, 'w'), indent=2)
"
sudo systemctl restart docker
sudo usermod -aG docker $USER
newgrp docker
```

> **Why `host` cgroup mode?** In cgroup v2, the default `private` namespace mode can prevent GPU processes inside containers from properly reporting metrics and can interfere with NVIDIA's container toolkit.

---

## 2.10 Verification

After completing all steps, verify the setup:

```bash
# From Spark 1 — ping Spark 2
ping -c 4 192.168.86.26

# SSH into Spark 2
ssh moonlit@192.168.86.26 "hostname && nvidia-smi -L"
# Expected: spark-7229 and GPU 0: NVIDIA GB10 ...

# Check Docker cgroup configuration
docker info | grep "Cgroup Version"
# Expected: Cgroup Version: 2

# Verify Docker has nvidia runtime
docker info | grep -A5 Runtimes
# Should include: nvidia: ...
```

---

## Summary

At the end of this chapter you have:

- [x] Both DGX Sparks physically connected (power, network, QSFP)
- [x] First-boot wizard completed on both units
- [x] Static IPs assigned (Spark 1: `192.168.86.30`, Spark 2: `192.168.86.26`)
- [x] Persistent iptables rules saving router subnet access
- [x] SSH working from Spark 1 to Spark 2
- [x] Docker configured for cgroup v2 and NVIDIA runtime

---

*Continue to Chapter 3 to update the OS, CUDA drivers, and firmware.*


---

# Chapter 3 — CUDA and System Updates

## Overview

Before setting up Kubernetes or running any AI workloads, both DGX Sparks must be fully updated. This includes the OS, CUDA drivers, firmware, and all system packages. Running on outdated drivers causes subtle failures — from incorrect GPU memory reporting to NCCL compatibility errors in multi-node training.

This chapter covers two update methods: the DGX Dashboard (recommended) and the terminal.

## Prerequisites

- Both DGX Sparks powered on and connected to the internet
- Monitor connected to Spark 1 (for DGX Dashboard method)
- Static IPs configured (see Chapter 2)
- SSH access from Spark 1 to Spark 2

---

## 3.1 Method 1 — DGX Dashboard (Recommended)

The DGX Dashboard is a browser-based management interface that NVIDIA provides with every DGX Spark. It handles OS, CUDA driver, firmware, and system package updates in the correct order with automatic dependency resolution.

### Launching the Dashboard

1. Look for the `dgx-spark-dashboard.desktop` file on the desktop
2. **Right-click** → **Allow Launching** (required the first time — DGX OS marks desktop files as untrusted by default)
3. **Double-click** to open the dashboard in the browser

Alternatively, open a browser and navigate directly to:

```
http://localhost
```

### Running Updates

1. Log in to the DGX Dashboard with your user credentials
2. On the main screen, look for the **"Update Available"** banner or button
3. Click **"Update Now"**
4. The system will download and apply updates — this may take 15–30 minutes per round
5. The system may reboot automatically when required
6. After reboot, **check for updates again** — multiple rounds are expected

> **Important:** It is completely normal to see "Update Available" multiple times in a row. Some updates are staged — they only become visible after previous layers are installed. Keep clicking "Update Now" after each reboot until the dashboard shows no pending updates.

**Typical update sequence:**
- Round 1: Base OS packages and kernel updates
- Round 2: CUDA driver updates (requires Round 1 kernel)
- Round 3: Firmware updates (requires Round 2 drivers)
- Round 4: Final package cleanup

### Updating Spark 2

The DGX Dashboard only manages the Spark it runs on. To update Spark 2:

1. Open a browser on Spark 1 and navigate to `http://192.168.86.26` — the DGX Dashboard on Spark 2 is accessible over the network
2. Log in and run updates the same way
3. Or use the terminal method below via SSH

---

## 3.2 Method 2 — Terminal Updates

The terminal method is useful for scripting, for updating Spark 2 over SSH, or when the DGX Dashboard is unavailable.

Run on each Spark (directly or via SSH for Spark 2):

```bash
# Update package index
sudo apt update

# Full distribution upgrade (handles kernel and CUDA dependencies)
sudo apt dist-upgrade -y

# Firmware updates
sudo fwupdmgr refresh
sudo fwupdmgr upgrade

# Reboot to apply kernel and driver updates
sudo reboot
```

After rebooting, repeat until `apt dist-upgrade` shows no packages to upgrade and `fwupdmgr upgrade` reports all firmware is current.

> **Why `dist-upgrade` instead of `upgrade`?** The standard `apt upgrade` will not install updated kernels or resolve complex dependency changes. `dist-upgrade` handles package replacement and dependency resolution required for CUDA driver updates.

---

## 3.3 Verifying Updates

After all updates complete, verify the installed versions on both Sparks:

```bash
# OS version
cat /etc/os-release | grep PRETTY_NAME
# Expected: Ubuntu 24.04.4 LTS

# Kernel version
uname -r
# Expected: 6.17.0-1018-nvidia

# CUDA driver version (via nvidia-smi)
nvidia-smi
# Look for "CUDA Version:" in the top right of the output

# Driver version
nvidia-smi --query-gpu=driver_version --format=csv,noheader
# Expected: 580.159.03

# CUDA runtime version
nvcc --version
# Expected: release 13.0
```

> **Common Pitfall: `nvcc: command not found`**
>
> `nvidia-smi` and `nvcc` are different tools. `nvidia-smi` ships with the GPU driver and is always in PATH after a driver install. `nvcc` is the CUDA compiler and may not be in PATH by default, even after a full DGX update.
>
> If `nvcc --version` fails, check whether it is installed but not in PATH:
> ```bash
> find /usr/local -name nvcc 2>/dev/null
> # Common location: /usr/local/cuda/bin/nvcc
>
> # Add to PATH permanently if found:
> echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
> source ~/.bashrc
> nvcc --version
> ```
>
> If `nvcc` is absent, that is acceptable for this setup. The GPU driver and CUDA runtime inside containers (which vLLM uses) are what matter. `nvcc` is only needed for building custom CUDA kernels, which this guide does not require.

### Expected Versions After Full Update

| Component | Expected Version |
|-----------|-----------------|
| OS | Ubuntu 24.04.4 LTS |
| Kernel | 6.17.0-1018-nvidia |
| CUDA Driver | 580.159.03 |
| CUDA Runtime | 13.0 |
| GPU (confirmed) | NVIDIA GB10 Blackwell |

### Verifying GPU Access

```bash
# Confirm GPU is visible and healthy
nvidia-smi

# Expected output (partial):
# +-----------------------------------------------------------------------+
# | NVIDIA-SMI 580.159.03    Driver Version: 580.159.03  CUDA Version: 13.0 |
# |---------|------------------------|----------------------|
# |   GPU   Name          Persistence-M | Bus-Id     Disp.A | Volatile Uncorr. ECC |
# |=========|========================|======================|
# |   0     NVIDIA GB10             Off |  ...                |                   |
# +-----------------------------------------------------------------------+
```

---

## 3.4 Notes on Update Order

**Always update both Sparks before proceeding to Chapter 4.**

The GPU Operator (installed in Chapter 4) installs CUDA-version-aware components. If the driver version differs between nodes, the operator may install incompatible component versions. Update both nodes to identical versions first.

> **Production Note: Why version consistency between nodes matters**
>
> The NVIDIA GPU Operator uses the driver version on each node to decide which CUDA container toolkit and device plugin image to pull. In a 2-node cluster, if Spark 1 is on driver 580.159.03 and Spark 2 is on an older version, the operator will deploy different toolkit images per node. This creates subtle runtime differences — a container that works on Spark 1 may fail on Spark 2 with a CUDA ABI error.
>
> The `nvidia-smi --query-gpu=driver_version` command you ran in Section 3.3 makes this easy to verify. If the two outputs don't match exactly, run the update sequence on the lagging node before continuing.

**Spark 2 via SSH:**

```bash
# From Spark 1 — run full update sequence on Spark 2
ssh moonlit@192.168.86.26 "sudo apt update && sudo apt dist-upgrade -y"
ssh moonlit@192.168.86.26 "sudo fwupdmgr refresh && sudo fwupdmgr upgrade"
ssh moonlit@192.168.86.26 "sudo reboot"

# Wait ~2 minutes for Spark 2 to reboot, then verify
ssh moonlit@192.168.86.26 "nvidia-smi --query-gpu=driver_version --format=csv,noheader"
```

---

## Summary

At the end of this chapter you have:

- [x] Spark 1 fully updated (OS, CUDA 13.0, driver 580.159.03, firmware)
- [x] Spark 2 fully updated with identical versions
- [x] GPU confirmed visible and healthy on both nodes via `nvidia-smi`

---

*Continue to Chapter 4 to install Kubernetes with k3s across both nodes.*


---

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


---

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


---

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


---

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


---

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


---

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


---

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


---

