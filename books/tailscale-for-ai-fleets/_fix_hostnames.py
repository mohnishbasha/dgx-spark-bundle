#!/usr/bin/env python3
"""Replace fictional spark hostnames/IPs with real ones; mask last two octets with xx."""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))

FILES = [
    "chapter-01.html",
    "chapter-04.html",
    "cheatsheet.html",
    "troubleshooting.html",
    "03-chapter-01-introduction.md",
    "06-chapter-04-client-ssh.md",
    "07-cheatsheet.md",
    "08-troubleshooting.md",
]

# Masked IP addresses (last two octets replaced with xx)
IP_MAC    = "100.124.xx.xx"  # macbook
IP_B1_1   = "100.109.xx.xx"  # spark-bundle1-1
IP_B1_2   = "100.104.xx.xx"  # spark-bundle1-2
IP_B2_1   = "100.70.xx.xx"   # spark-bundle2-1
IP_B2_2   = "100.67.xx.xx"   # spark-bundle2-2

REAL_STATUS = (
    f"100.124.xx.xx  serverlesss-macbook-pro  mohnishbasha@   macOS  -\n"
    f"100.109.xx.xx  spark-bundle1-1          tagged-devices  linux  -\n"
    f"100.104.xx.xx  spark-bundle1-2          tagged-devices  linux  -\n"
    f"100.70.xx.xx   spark-bundle2-1          tagged-devices  linux  -\n"
    f"100.67.xx.xx   spark-bundle2-2          tagged-devices  linux  -"
)

# Old 2-node status block (fictional)
OLD_STATUS_2 = (
    "100.124.185.100  serverlesss-macbook-pro  mohnishbasha@   macOS  -\n"
    "100.80.57.99     spark-5f59               tagged-devices  linux  -\n"
    "100.70.22.119    spark-6126               tagged-devices  linux  -"
)

NEW_JSON_PEERS = (
    '{\n'
    '  "name": "spark-bundle1-1",\n'
    '  "tags": ["tag:spark"]\n'
    '}\n'
    '{\n'
    '  "name": "spark-bundle1-2",\n'
    '  "tags": ["tag:spark"]\n'
    '}\n'
    '{\n'
    '  "name": "spark-bundle2-1",\n'
    '  "tags": ["tag:spark"]\n'
    '}\n'
    '{\n'
    '  "name": "spark-bundle2-2",\n'
    '  "tags": ["tag:spark"]\n'
    '}'
)

def fix(text):
    # 1. Replace old 2-node status block with real 4-node masked block
    text = text.replace(OLD_STATUS_2, REAL_STATUS)

    # 2. Replace old fictional status block variant (in case it was already partially updated)
    text = text.replace(
        "100.124.185.100  serverlesss-macbook-pro  mohnishbasha@   macOS  -",
        "100.124.xx.xx  serverlesss-macbook-pro  mohnishbasha@   macOS  -"
    )

    # 3. Hostname replacements
    text = text.replace("spark-5f59", "spark-bundle2-1")
    text = text.replace("spark-6126", "spark-bundle2-2")

    # 4. IP replacements — order matters: replace old spark-6126 IP first
    #    since its replacement (100.70.xx.xx) is also spark-bundle2-1's new display IP
    text = text.replace("100.70.22.119", IP_B2_1)   # old spark-6126 → spark-bundle2-1 masked
    text = text.replace("100.80.57.99",  IP_B2_2)   # old spark-5f59 → spark-bundle2-2 masked
    text = text.replace("100.124.185.100", IP_MAC)
    text = text.replace("100.109.226.75", IP_B1_1)
    text = text.replace("100.104.224.127", IP_B1_2)
    text = text.replace("100.67.150.97",  IP_B2_2)

    # 5. Fix JSON peer inspection output (2 nodes → 4 nodes)
    old_json_2 = (
        '{\n'
        '  "name": "spark-bundle2-1",\n'
        '  "tags": ["tag:spark"]\n'
        '}\n'
        '{\n'
        '  "name": "spark-bundle2-2",\n'
        '  "tags": ["tag:spark"]\n'
        '}'
    )
    text = text.replace(old_json_2, NEW_JSON_PEERS)

    return text

for fname in FILES:
    path = os.path.join(HERE, fname)
    if not os.path.exists(path):
        print(f"  SKIP (not found): {fname}")
        continue
    with open(path, encoding="utf-8") as f:
        original = f.read()
    updated = fix(original)
    if updated != original:
        with open(path, "w", encoding="utf-8") as f:
            f.write(updated)
        print(f"  updated: {fname}")
    else:
        print(f"  unchanged: {fname}")
