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
