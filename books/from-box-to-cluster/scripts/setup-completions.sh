#!/usr/bin/env bash
# setup-completions.sh
#
# Install bash tab-completion for the CLI tools used across the
# "From Box to Cluster" DGX Spark Bundle guide.
#
# Idempotent: safe to re-run. Lines already present in ~/.bashrc are skipped.
# Each completion line is guarded by `command -v`, so tools that aren't
# installed yet are silently ignored — completions light up automatically
# once the tool is on PATH.
#
# Usage (on both Spark 1 and Spark 2):
#   curl -fsSL https://mohnishbasha.github.io/dgx-spark-bundle/books/from-box-to-cluster/scripts/setup-completions.sh | bash
# or:
#   ./setup-completions.sh

set -euo pipefail

BASHRC="${HOME}/.bashrc"
MARKER="# --- dgx-spark-bundle: shell completions ---"

# Append a block once; skip if the marker line is already in ~/.bashrc.
if grep -qF "$MARKER" "$BASHRC" 2>/dev/null; then
  echo "✓ Completions block already present in $BASHRC — skipping append."
else
  echo "→ Adding completions block to $BASHRC"
  {
    echo ""
    echo "$MARKER"
    echo 'command -v kubectl >/dev/null && source <(kubectl completion bash)'
    echo 'command -v helm    >/dev/null && source <(helm completion bash)'
    echo 'command -v gh      >/dev/null && source <(gh completion -s bash)'
    echo 'command -v uv      >/dev/null && eval "$(uv generate-shell-completion bash)"'
    echo 'command -v poetry  >/dev/null && source <(poetry completions bash)'
    echo "# --- end dgx-spark-bundle ---"
  } >> "$BASHRC"
fi

echo ""
echo "Done. Open a new shell, or run: source ~/.bashrc"
echo "Verify with: kubectl <Tab><Tab>  and  helm <Tab><Tab>"
