# Chapter 4: Client Setup and SSH Access

This chapter covers setup from the operator's perspective — the engineer SSHing into a Spark from their laptop. At this point the Sparks are enrolled and tagged (Chapter 2), and the ACL is configured (Chapter 3).

## Step 1 — Install Tailscale on macOS

```bash
brew install tailscale
```

Start the daemon:

```bash
sudo brew services start tailscale
```

## Step 2 — Login and Verify

Authenticate to the tailnet:

```bash
tailscale login
```

This opens a browser to the Tailscale login page. Sign in with the same account whose email is in `group:operators`. On success:

```
Success.
```

Connect to the tailnet:

```bash
tailscale up
```

Check network status:

```bash
tailscale status
```

Expected output:

```
100.124.xx.xx  serverlesss-macbook-pro  mohnishbasha@   macOS  -
100.109.xx.xx  spark-bundle1-1          tagged-devices  linux  -
100.104.xx.xx  spark-bundle1-2          tagged-devices  linux  -
100.70.xx.xx   spark-bundle2-1          tagged-devices  linux  -
100.67.xx.xx   spark-bundle2-2          tagged-devices  linux  -
```

Confirm both Sparks carry `tag:spark`:

```bash
tailscale status --json | jq '.Peer[] | {name: .HostName, tags: .Tags}'
```

Expected output:

```json
{
  "name": "spark-bundle1-1",
  "tags": ["tag:spark"]
}
{
  "name": "spark-bundle1-2",
  "tags": ["tag:spark"]
}
{
  "name": "spark-bundle2-1",
  "tags": ["tag:spark"]
}
{
  "name": "spark-bundle2-2",
  "tags": ["tag:spark"]
}
```

If a machine shows `"tags": null`, return to the admin console and apply the tag (Chapter 2, Step 3).

## Step 3 — SSH into a Spark Node

By Tailscale IP:

```bash
tailscale ssh stoke@100.70.xx.xx
```

By MagicDNS hostname:

```bash
tailscale ssh stoke@spark-bundle2-2.tail8a84f6.ts.net
```

Or using plain ssh:

```bash
ssh stoke@100.70.xx.xx
```

A successful connection shows the DGX Spark welcome banner and drops you into a shell as `stoke`:

```
Welcome to Ubuntu 22.04.x LTS (GNU/Linux 6.x.x aarch64)

stoke@spark-bundle2-2:~$
```

## Summary

| Capability | How it works |
|------------|-------------|
| SSH to spark-bundle2-1 | `tailscale ssh stoke@100.67.xx.xx` |
| SSH to spark-bundle2-2 | `tailscale ssh stoke@100.70.xx.xx` or hostname |
| Add a new operator | Invite to tailnet + add login to `group:operators` |
| Remove an operator | Remove from tailnet — access revoked everywhere instantly |
| Add a new Spark | Enroll it + apply `tag:spark` — ACL covers it automatically |
