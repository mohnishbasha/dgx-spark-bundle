# Chapter 1: Introduction — The Networking Problem

You have two NVIDIA DGX Spark machines. They are powerful, quiet, and ready to run frontier-scale AI workloads. The only question is: how do you — and your team — actually get into them?

The classic answer is SSH keys distributed to everyone who needs access, firewall rules punched through for each machine, and a growing spreadsheet of who has which key on which laptop. That works fine for one machine and one person. For a small AI fleet accessed by multiple engineers, it becomes operational debt almost immediately.

## The Networking Problem with a DGX Fleet

A two-node DGX Spark setup has a deceptively simple surface area, but the networking headaches compound quickly:

- **Static IPs change.** If your lab network changes, every SSH config and firewall rule must be updated.
- **Key rotation is manual.** When someone leaves, you must log into every machine and remove their key — a step that is easy to miss under pressure.
- **VPN complexity.** Traditional VPNs introduce a hub-and-spoke bottleneck; all traffic routes through a central server even when two peers are on the same LAN.
- **No audit trail.** Vanilla SSH gives you auth logs, but not a centralized view of who can reach what.

> **The invisible risk:** The worst outcome is not a breach — it is a former team member whose key was never removed, silently retaining access to machines running proprietary models for months.

## What You Want Instead

You want a system where:

- Any authorized engineer can SSH into any Spark from any device — laptop, desktop, or cloud VM — without exchanging keys manually.
- Access is controlled by identity, not by which machine the engineer happens to be on.
- Revoking access for one person immediately and completely is a single admin action.
- Adding a new Spark to the fleet automatically falls under the same access rules as every existing one.

That is exactly what Tailscale delivers.

## How Tailscale Works

Tailscale builds a **tailnet** — a private WireGuard mesh network — across all your enrolled devices. WireGuard handles the encrypted tunnels; Tailscale handles the key exchange and peer discovery so you never have to configure WireGuard directly.

| Component | Role |
|-----------|------|
| WireGuard | Encrypted peer-to-peer tunnels between all tailnet nodes |
| Identity | OAuth/OIDC — each user authenticates via Google, GitHub, or Microsoft |
| ACL Policy | HuJSON file declaring who can reach what; enforced on every node |
| MagicDNS | Stable hostnames (e.g. `spark-bundle2-2.tail8a84f6.ts.net`) for every device |

### Tailscale SSH

When you start Tailscale with `--ssh`, it intercepts SSH on the tailnet interface and replaces password/key authentication with tailnet identity checks. The ACL policy is the sole authorization mechanism — no `~/.ssh/authorized_keys` required.

After setup, SSH looks like:

```bash
ssh stoke@spark-bundle2-2.tail8a84f6.ts.net
```

No key to specify, no password prompt. The system only asks: "is this device on the tailnet and does the ACL allow it to SSH here?"

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         TAILNET                                  │
│                                                                  │
│   ┌──────────────────┐         ┌──────────────────┐             │
│   │   spark-bundle2-1     │─────────│   spark-bundle2-2     │             │
│   │  100.67.xx.xx    │WireGuard│  100.70.xx.xx   │             │
│   │  tag:spark       │         │  tag:spark       │             │
│   └──────────────────┘         └──────────────────┘             │
│             ▲                           ▲                        │
│             │    ACL: group:operators   │                        │
│             │    may SSH → tag:spark    │                        │
│             │    as user: stoke         │                        │
│   ┌──────────────────────────────────────────────────┐          │
│   │  macOS laptop   100.124.xx.xx                  │          │
│   │  mohnishbasha@  (group:operators member)         │          │
│   └──────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### Setup Sequence

| Step | Where | Chapter |
|------|-------|---------|
| 1. Install Tailscale & enable SSH on each Spark | Terminal on each Spark | Ch 2 |
| 2. Apply `tag:spark` to each machine | Tailscale admin console | Ch 2 |
| 3. Invite operators to the tailnet | Tailscale admin console | Ch 3 |
| 4. Define groups, tags, and SSH rule in ACL | Tailscale admin console | Ch 3 |
| 5. Install Tailscale on operator laptops, login | Each operator's machine | Ch 4 |
| 6. SSH into Sparks via IP or MagicDNS hostname | Any operator device | Ch 4 |
