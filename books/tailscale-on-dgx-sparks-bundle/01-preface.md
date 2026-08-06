# Preface

## Why We Wrote This Runbook

When you stand up two NVIDIA DGX Spark machines and want to SSH between them — or let a colleague log in from a laptop — the default answer is "set up SSH keys and open firewall ports." On a home lab or startup network this is manageable. On a fleet that spans offices, cloud VMs, and developer laptops, it becomes a maintenance burden: rotating keys, updating firewall rules every time someone joins or leaves, and hoping nothing drifts out of sync.

Tailscale eliminates that entire class of problem. It builds a WireGuard mesh between all your devices, and lets you declare who can SSH into what with a single JSON policy file. Onboarding a new engineer is one admin-console invite. Offboarding is removing them from the tailnet — and every machine in the fleet immediately enforces the change.

We run two DGX Sparks in our lab. Getting Tailscale onto them, tagging them correctly, writing the ACL, and verifying that a MacBook could SSH into either node without a password took less than thirty minutes. This runbook is exactly what we did, in the order we did it.

## What This Runbook Covers

- **Machine enrollment** — install Tailscale on each Spark, enable SSH mode, authenticate to the tailnet
- **Tagging** — apply `tag:spark` so one ACL rule covers the whole fleet
- **Access control** — define `group:operators`, set tag ownership, write the SSH accept rule
- **Client setup** — install Tailscale on macOS, login, verify peer visibility, SSH via IP or MagicDNS hostname
- **Operations** — troubleshooting, version mismatches, checking SSH enable state

## Who This Is For

This runbook assumes you already have DGX Spark hardware running and you are comfortable with a Linux terminal. No prior Tailscale or WireGuard experience is required — every concept is explained the first time it appears.

> **Companion book:** If you are setting up the DGX Sparks from scratch — first boot, static IPs, k3s, KubeRay, vLLM — see the companion book *From Box to Cluster*. This runbook picks up where networking configuration leaves off.

*— Mohinish Shaikh, August 2026*
