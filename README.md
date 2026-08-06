# DGX Spark Bundle — Open Technical Books

Open technical books on AI infrastructure, GPU computing, and distributed systems by [Mohinish Shaikh](https://github.com/mohnishbasha) and collaborators.

**Site:** https://mohnishbasha.github.io/dgx-spark-bundle/

---

## Books

| # | Title | Description | Stack | Read |
|---|-------|-------------|-------|------|
| 1 | **From Box to Cluster** — Building a Personal AI Supercomputer with NVIDIA DGX Spark Bundle | Step-by-step guide to configuring two DGX Spark units into a production AI inference cluster | DGX OS · k3s · GPU Operator · KubeRay · vLLM · AIBrix · Prometheus/Grafana | [books/from-box-to-cluster/](https://mohnishbasha.github.io/dgx-spark-bundle/books/from-box-to-cluster/) |
| 2 | **Tailscale for AI Fleets** — Secure Mesh Networking for the DGX Spark Bundle | Practical runbook for enrolling DGX Spark nodes in a Tailscale WireGuard mesh with tag-based ACL and password-free SSH | Tailscale · WireGuard · MagicDNS · Tailscale SSH · ACL policy | [books/tailscale-for-ai-fleets/](https://mohnishbasha.github.io/dgx-spark-bundle/books/tailscale-for-ai-fleets/) |

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
