# DGX Spark Bundle — Open Technical Books

Open technical books on AI infrastructure, GPU computing, and distributed systems by [Mohinish Shaikh](https://github.com/mohnishbasha) and collaborators.

**Site:** https://mohnishbasha.github.io/dgx-spark-bundle/

---

## Books

### Book 1 — From Box to Cluster: Building a Personal AI Supercomputer with NVIDIA DGX Spark Bundle

Step-by-step guide to configuring two NVIDIA DGX Spark units into a production AI inference cluster running vLLM, KubeRay, k3s, and AIBrix.

- **Stack:** DGX OS · k3s · NVIDIA GPU Operator · KubeRay · vLLM · AIBrix · Prometheus/Grafana
- **Hardware:** 2× GB10 Blackwell GPUs · 256 GB unified memory · ConnectX-7 RDMA
- **Read:** [books/from-box-to-cluster/](https://mohnishbasha.github.io/dgx-spark-bundle/books/from-box-to-cluster/)

---

### Book 2 — Tailscale on DGX Spark Bundle: Zero-Config Secure Networking for Your AI Fleet

Practical runbook for enrolling DGX Spark nodes in a Tailscale mesh network, configuring ACL policy, and establishing password-free SSH access from macOS clients — in under 30 minutes.

- **Stack:** Tailscale · WireGuard · MagicDNS · Tailscale SSH · ACL policy
- **Hardware:** 2× DGX Spark nodes · macOS client
- **Chapters:** 4 (Fleet Setup · Machine Enrollment · ACL Policy · Client SSH Access)
- **Read:** [books/tailscale-for-ai-fleets/](https://mohnishbasha.github.io/dgx-spark-bundle/books/tailscale-for-ai-fleets/)

---

## Repository Structure

```
dgx-spark-bundle/
├── index.html                              # Books landing page
├── robots.txt                              # Crawler policy
├── llms.txt                                # AI/LLM crawler index
├── books/
│   ├── from-box-to-cluster/
│   │   ├── index.html                      # Full ebook (single-page)
│   │   ├── styles.css
│   │   ├── README.md
│   │   └── dist/                           # Generated artifacts
│   └── tailscale-for-ai-fleets/
│       ├── index.html                      # Full ebook (single-page)
│       ├── README.md
│       └── dist/                           # Generated artifacts
└── .github/workflows/pages.yml             # GitHub Pages deployment
```

## Contributing

Issues and pull requests are welcome. Content is licensed under [CC BY 4.0](LICENSE).

## Authors

- **Mohinish Shaikh** — [GitHub](https://github.com/mohnishbasha) · [LinkedIn](https://www.linkedin.com/in/mohinishbasha/)
- **Sanwi Sarode** — [GitHub](https://github.com/sanwisarode) · [LinkedIn](https://www.linkedin.com/in/sanwi-sarode-785b0b282/)

## License

[Creative Commons Attribution 4.0 International (CC BY 4.0)](LICENSE)
