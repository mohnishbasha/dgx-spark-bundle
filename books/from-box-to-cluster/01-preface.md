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
