# Tailscale Network Access

## 1. Install Tailscale

```bash
brew install tailscale
```

## 2. Start the daemon

```bash
sudo brew services start tailscale
```

## 3. Login

```bash
tailscale login
```

Visit the URL printed in the terminal (e.g. `https://login.tailscale.com/a/...`) to authenticate via browser. On success the command prints `Success.`

## 4. Bring up the connection

```bash
tailscale up
```

## 5. Verify network status

```bash
tailscale status
```

Expected output shows your machine and the Spark nodes:

```
100.124.185.100  serverlesss-macbook-pro  mohnishbasha@   macOS  -
100.80.57.99     spark-5f59               tagged-devices  linux  -
100.70.22.119    spark-6126               tagged-devices  linux  -
```

## 6. Inspect peer tags

```bash
tailscale status --json | jq '.Peer[] | {name: .HostName, tags: .Tags}'
```

Both Spark nodes carry `tag:spark`. SSH access is governed by ACL rules tied to this tag.

## 7. SSH into a Spark node

Use either the Tailscale IP or the full MagicDNS hostname:

```bash
tailscale ssh stoke@100.70.22.119
# or
tailscale ssh stoke@spark-6126.tail8a84f6.ts.net
```

A successful connection shows the DGX Spark welcome banner.

## Troubleshooting

**`permission denied` on SSH**
The ACL policy for the target node (`tag:spark`) may not grant your user SSH access. Verify in the Tailscale admin console that your device or user is allowed to SSH to `tag:spark` nodes. `spark-5f59` currently returns `permission denied` while `spark-6126` is accessible — check whether the ACL differs between the two nodes.

**Client/server version mismatch warning**
```
Warning: client version "1.102.2-..." != tailscaled server version "1.102.1-..."
```
This is cosmetic. Restart the daemon to sync versions:
```bash
sudo brew services restart tailscale
```

**Check whether SSH is enabled on this machine**
```bash
tailscale debug prefs | grep -i runssh
```
`"RunSSH": false` means this machine does not accept inbound Tailscale SSH. To enable it: `sudo tailscale up --ssh`.
