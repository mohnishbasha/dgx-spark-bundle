# Chapter 3: Configuring Access Control Policy

Tailscale access control lives in a single JSON policy file managed through the admin console. This file is the source of truth for your entire tailnet. Every node checks this policy in real time — a change takes effect immediately without restarting daemons or rotating keys.

## Step 1 — Invite Users to the Tailnet

Each person who needs SSH access must first join the fleet tailnet.

**In the admin console:**

1. Go to **login.tailscale.com/admin/users**
2. Click **Invite users**
3. Enter the email address associated with the engineer's Google, GitHub, or Microsoft account
4. The engineer accepts the invitation using their existing login

> **Their login becomes their identity.** The email the engineer uses to accept (e.g. `alice@gmail.com`) is what you reference in the ACL policy. Know which email they will use before writing the `groups` entry.

| Action | How to do it | Takes effect |
|--------|-------------|--------------|
| Add a new operator | Invite to tailnet + add login to `group:operators` | Immediately on ACL save |
| Remove an operator | Remove from tailnet or from `group:operators` | Immediately everywhere |
| Temporarily suspend | Remove from `group:operators` only | Immediately |

## Step 2 — Define Groups and Tag Ownership

In the admin console, navigate to **Access controls**. Add the `groups` and `tagOwners` blocks:

```json
"groups": {
  // Each entry is a Tailscale login (the email used to accept the invite).
  "group:operators": ["alice@gmail.com", "bob@company.com"]
},

"tagOwners": {
  // autogroup:admin means only tailnet admins can apply this tag.
  "tag:spark": ["autogroup:admin"]
},
```

> **tagOwners must be declared before the tag is used.** If you try to apply `tag:spark` before adding it to `tagOwners`, the console will reject it. Define `tagOwners` first, save, then apply the tag to machines (Chapter 2, Step 3).

## Step 3 — Write the SSH Accept Rule

Add this block to the policy:

```json
"ssh": [
  {
    "action": "accept",
    "src":    ["group:operators"],
    "dst":    ["tag:spark"],
    "users":  ["stoke"]
  }
]
```

Reading the rule: *people in `group:operators` may SSH into any machine tagged `tag:spark`, landing as Linux user `stoke`.*

| Field | Value | Meaning |
|-------|-------|---------|
| `action` | `"accept"` | Allow the connection |
| `src` | `["group:operators"]` | Tailscale identities allowed to initiate SSH |
| `dst` | `["tag:spark"]` | Any device carrying this tag |
| `users` | `["stoke"]` | Linux user to log in as on the destination |

### Why tag:spark as dst is powerful

The destination is a tag, not a list of machine names or IPs. When you add a third DGX Spark and tag it `tag:spark`, it is instantly covered by this rule — no policy edit required.

### Complete policy example

```json
{
  "groups": {
    "group:operators": ["alice@gmail.com", "bob@company.com"]
  },
  "tagOwners": {
    "tag:spark": ["autogroup:admin"]
  },
  "acls": [
    {
      "action": "accept",
      "src":    ["group:operators"],
      "dst":    ["tag:spark:*"]
    }
  ],
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
