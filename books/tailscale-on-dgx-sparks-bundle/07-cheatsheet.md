# Command Cheatsheet

## On the Spark Machine (Linux / Ubuntu ARM64)

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Enable Tailscale with SSH mode, self-apply tag, and connect
sudo tailscale up --ssh --advertise-tags=tag:spark

# Check daemon status
sudo systemctl status tailscaled

# Verify on the tailnet
tailscale status

# Check whether SSH mode is enabled
tailscale debug prefs | grep -i runssh

# Enable SSH mode and re-apply tag on an already-connected machine
sudo tailscale up --ssh --advertise-tags=tag:spark
```

## On the Operator Laptop (macOS)

```bash
# Install Tailscale
brew install tailscale

# Start the daemon
sudo brew services start tailscale

# Restart the daemon (fix version mismatch warnings)
sudo brew services restart tailscale

# Authenticate to the fleet tailnet
tailscale login

# Connect to the tailnet
tailscale up

# Show all tailnet peers
tailscale status

# Inspect peer tags (requires jq)
tailscale status --json | jq '.Peer[] | {name: .HostName, tags: .Tags}'
```

## SSH Commands

```bash
# SSH by Tailscale IP
tailscale ssh stoke@100.70.xx.xx
tailscale ssh stoke@100.67.xx.xx

# SSH by MagicDNS hostname
tailscale ssh stoke@spark-bundle2-2.tail8a84f6.ts.net

# SSH with plain ssh
ssh stoke@100.70.xx.xx
```

## Admin Console Quick Reference

| Task | Admin Console Path |
|------|--------------------|
| Invite a user | Users → Invite users |
| Remove a user | Users → (user) → Remove |
| Edit ACL policy | Access controls |
| Apply tag to a machine | Machines → (machine) → ⋯ → Edit ACL tags |
| View Tailscale IP | Machines → (machine row) |
| View MagicDNS hostname | Machines → (machine) → Machine details |
| Check key expiry | Machines → (machine) → Machine details → Key expiry |

## Minimum Working ACL Policy

```json
{
  "groups": {
    "group:operators": ["alice@gmail.com", "bob@company.com"]
  },
  "tagOwners": {
    "tag:spark": ["autogroup:admin"]
  },
  "ssh": [
    {
      "action": "accept",
      "src":    ["group:operators"],
      "dst":    ["tag:spark"],
      "users":  ["stoke"]
    }
  ]
}
```
