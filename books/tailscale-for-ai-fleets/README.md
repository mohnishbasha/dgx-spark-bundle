# Tailscale for AI Fleets: Secure Mesh Networking for the DGX Spark Bundle

**Read online:** https://mohnishbasha.github.io/dgx-spark-bundle/books/tailscale-for-ai-fleets/

Practical runbook for enrolling NVIDIA DGX Spark nodes in a Tailscale WireGuard mesh, configuring ACL policy with tag-based SSH access, and connecting from a macOS client — in under 30 minutes. No firewall rules, no SSH key management.

> **Companion book:** For setting up DGX Sparks from scratch (k3s, KubeRay, vLLM), see [From Box to Cluster](../from-box-to-cluster/).

---

## What You'll Build

```
MacBook  ──── Tailnet ────  spark-5f59  (DGX Spark 1)
                       └──  spark-6126  (DGX Spark 2)

tag:spark → SSH accept rule → group:operators
```

- 2 Spark nodes enrolled with `tag:spark`
- 1 ACL policy granting SSH access to operators
- MagicDNS SSH — no passwords, no key distribution

## Stack

| Component | Role |
|-----------|------|
| Tailscale | Mesh VPN control plane |
| WireGuard | Encrypted data plane |
| MagicDNS | Hostname resolution across tailnet |
| Tailscale SSH | Password-free SSH governed by ACL |
| ACL policy (HuJSON) | Declarative access control |

---

## Table of Contents

### Part I — Fleet Setup

| Chapter | Title | Key Topics |
|---------|-------|------------|
| 1 | Introduction: The Networking Problem | Why Tailscale, WireGuard mesh, tailnet concepts, architecture |
| 2 | Enrolling the Spark Machines | Install, `tailscale up --ssh`, login URL, tag application |

### Part II — Access Control

| Chapter | Title | Key Topics |
|---------|-------|------------|
| 3 | Configuring Access Control Policy | Invite users, groups, tagOwners, SSH accept rule |
| 4 | Client Setup and SSH Access | macOS install, login, verify status, MagicDNS SSH |

### Back Matter

| Section | Contents |
|---------|----------|
| Command Cheatsheet | Quick-reference for all Tailscale CLI commands |
| Troubleshooting | Permission denied, version mismatch, SSH not enabled |

---

## Source Files

```
tailscale-for-ai-fleets/
├── 00-cover.md
├── 01-preface.md
├── 02-toc.md
├── 03-chapter-01-introduction.md
├── 04-chapter-02-enroll-sparks.md
├── 05-chapter-03-acl-policy.md
├── 06-chapter-04-client-ssh.md
├── 07-cheatsheet.md
├── 08-troubleshooting.md
├── TAILSCALE.md                        # Quick-start reference
├── index.html                          # Single-page ebook
└── dist/                               # Generated artifacts
```

---

## Authors

- **Mohinish Shaikh** — [GitHub](https://github.com/mohnishbasha) · [LinkedIn](https://www.linkedin.com/in/mohinishbasha/)

*First Edition — August 2026 · Serverless Ventures LLC*

## License

[Creative Commons Attribution 4.0 International (CC BY 4.0)](../../LICENSE)
