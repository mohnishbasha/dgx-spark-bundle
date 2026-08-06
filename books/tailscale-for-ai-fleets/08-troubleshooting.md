# Troubleshooting

## `permission denied` when SSHing into a Spark

The ACL policy does not grant your tailnet identity SSH access to the target machine. Work through this checklist:

1. **Is your Tailscale login in `group:operators`?**
   Open Access controls and check the `groups` block. Your login email must appear there exactly as you authenticated.

2. **Does the target machine carry `tag:spark`?**
   Admin console → Machines. If no tag appears: ⋯ → Edit ACL tags → apply `tag:spark`. Verify with:
   ```bash
   tailscale status --json | jq '.Peer[] | {name: .HostName, tags: .Tags}'
   ```

3. **Is Tailscale SSH enabled on the Spark?**
   ```bash
   tailscale debug prefs | grep -i runssh
   ```
   If `"RunSSH": false`:
   ```bash
   sudo tailscale up --ssh --advertise-tags=tag:spark
   ```

4. **Is the Spark visible on the tailnet?**
   From your laptop: `tailscale status`. Both Spark hostnames should appear. If not, check the daemon on the machine:
   ```bash
   sudo systemctl status tailscaled
   ```

In our lab, `spark-bundle2-1` returned `permission denied` while `spark-bundle2-2` was accessible — the cause was that `spark-bundle2-1` had not yet been tagged. Applying `tag:spark` resolved it immediately.

---

## Client/server version mismatch warning

```
Warning: client version "1.102.2-..." != tailscaled server version "1.102.1-..."
```

This is **cosmetic**. It appears when the CLI binary and daemon are on different patch versions. SSH and network connectivity are not affected.

Fix on macOS:
```bash
sudo brew services restart tailscale
```

Fix on Linux:
```bash
sudo systemctl restart tailscaled
```

---

## Tailscale SSH is not enabled on this machine

```bash
tailscale debug prefs | grep -i runssh
```

If `"RunSSH": false`, enable it:

```bash
sudo tailscale up --ssh --advertise-tags=tag:spark
```

You do not need to re-authenticate. The command re-applies the flags to the existing connection.

---

## A Spark is not appearing in `tailscale status`

The machine has lost its connection. On the Spark:

```bash
sudo systemctl status tailscaled
# If inactive:
sudo systemctl restart tailscaled
sudo tailscale up --ssh --advertise-tags=tag:spark
```

If you see "needs login" or an authentication URL, the node key may have expired. Authenticate again via the printed URL — though tagged devices should not expire. If a tagged device prompts for re-login, check that the tag is still applied in the admin console.

---

## Error: `tag:spark` is not defined in the policy

The admin console rejects tag application when the tag is not declared in `tagOwners`. Open Access controls and confirm:

```json
"tagOwners": {
  "tag:spark": ["autogroup:admin"]
},
```

Save the policy first, then apply the tag in Machines → Edit ACL tags.

---

## Machine enrolled in the wrong tailnet

If you opened the authentication URL in a browser signed into a personal account instead of the fleet account:

```bash
# Log out from the Spark
sudo tailscale logout

# Re-enroll with the fleet account
sudo tailscale up --ssh --advertise-tags=tag:spark
```

Open the new URL in a browser signed into the correct fleet tailnet account. Then remove the stray device from your personal tailnet via the admin console.
