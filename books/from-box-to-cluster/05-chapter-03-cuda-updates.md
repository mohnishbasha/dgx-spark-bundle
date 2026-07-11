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
