# Chapter 2: Enrolling the Spark Machines

This chapter covers everything that happens on the Spark machines themselves: installing Tailscale, enabling SSH mode, and authenticating each node to the fleet tailnet. Repeat these steps on both Spark machines before moving to Chapter 3.

**Prerequisites:**

- SSH or physical access to each Spark running Ubuntu (ARM64)
- A Tailscale account on the fleet tailnet (admin account, not personal)
- Internet access from the Spark

## Step 1 — Install Tailscale

Tailscale provides a one-line installer. Run on each Spark:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

The script auto-detects Ubuntu ARM64 and installs from the official apt repository, then starts `tailscaled` as a systemd service.

Verify the daemon is running:

```bash
sudo systemctl status tailscaled
```

Expected output includes `Active: active (running)`.

## Step 2 — Bring Up Tailscale with SSH Mode and Tag

Run `tailscale up` with two flags: `--ssh` enables Tailscale SSH, and `--advertise-tags=tag:spark` self-applies the ACL tag at enrollment time — no manual admin console click required.

```bash
sudo tailscale up --ssh --advertise-tags=tag:spark
```

The command prints a login URL:

```
To authenticate, visit:

        https://login.tailscale.com/a/xxxxxxxxxxxxxxxx
```

> **Open the URL in the fleet account browser.** This URL must be opened in a browser signed into the **fleet tailnet account** — not a personal Tailscale account. If you sign into the wrong account, the machine joins the wrong tailnet and you will need to reauthenticate.

After approving in the browser, the terminal shows:

```
Success.
```

The Spark is now on the tailnet with SSH enabled and `tag:spark` applied. Verify:

```bash
tailscale status
```

> **tagOwners must be defined first.** The `tag:spark` tag must be declared in the ACL policy's `tagOwners` section before `--advertise-tags` will accept it. If you see an error, set up the ACL in Chapter 3 first, then re-run this command. Re-running on an already-connected machine simply re-applies the flags — no re-authentication needed.

### What each flag does

| Flag | Effect |
|------|--------|
| `--ssh` | Tailscale intercepts SSH on the tailnet interface; ACL policy becomes the sole auth check |
| `--advertise-tags=tag:spark` | Self-applies `tag:spark` at enrollment; no admin console click required |

## Step 3 — Verify the Tag in the Admin Console

The `--advertise-tags` flag handles tagging automatically, but confirm it in the admin console:

1. Go to **login.tailscale.com/admin/machines**
2. Find your Spark in the machine list
3. The **Owner** column should show **tagged-devices** (not your email) — tag is active
4. Click the machine row → **Machine details** to see the full tag list

If the tag is missing, click **⋯ → Edit ACL tags**, type `tag:spark` and confirm. Ensure `tagOwners` is defined in the ACL policy (Chapter 3).

### What tagging does to node key expiry

| Device type | Key expiry | Re-auth required |
|-------------|------------|------------------|
| Untagged (personal device) | ~180 days | Yes — human login needed |
| Tagged (server, e.g. `tag:spark`) | Never | No — automatic refresh |

Tagged devices never require re-authentication. This is the correct operational posture for any machine that must stay on the tailnet permanently.

### Checkpoint

At the end of this chapter both Spark machines should:

- Have `tailscaled` running as a systemd service
- Be connected to the fleet tailnet with a `100.x.x.x` IP
- Have Tailscale SSH enabled (`--ssh` flag)
- Carry the `tag:spark` ACL tag in the admin console
