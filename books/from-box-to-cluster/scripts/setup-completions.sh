#!/usr/bin/env bash
# setup-completions.sh
#
# Install bash tab-completion AND kubectl/helm aliases for the CLI tools
# used across the "From Box to Cluster" DGX Spark Bundle guide.
#
# Idempotent: safe to re-run. Blocks already present in ~/.bashrc are skipped.
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

# ── Completions ──────────────────────────────────────────────────────────────
COMPLETIONS_MARKER="# --- dgx-spark-bundle: shell completions ---"

if grep -qF "$COMPLETIONS_MARKER" "$BASHRC" 2>/dev/null; then
  echo "✓ Completions block already present in $BASHRC — skipping append."
else
  echo "→ Adding completions block to $BASHRC"
  {
    echo ""
    echo "$COMPLETIONS_MARKER"
    echo 'command -v kubectl >/dev/null && source <(kubectl completion bash)'
    echo 'command -v helm    >/dev/null && source <(helm completion bash)'
    echo 'command -v gh      >/dev/null && source <(gh completion -s bash)'
    echo 'command -v uv      >/dev/null && eval "$(uv generate-shell-completion bash)"'
    echo 'command -v poetry  >/dev/null && source <(poetry completions bash)'
    echo "# --- end completions ---"
  } >> "$BASHRC"
fi

# ── Aliases ──────────────────────────────────────────────────────────────────
# `k` for kubectl (+ tab-completion), plus common get/describe/logs/exec/apply
# shortcuts. `kns` switches the current context's default namespace.
ALIASES_MARKER="# --- dgx-spark-bundle: kubectl aliases ---"

if grep -qF "$ALIASES_MARKER" "$BASHRC" 2>/dev/null; then
  echo "✓ Aliases block already present in $BASHRC — skipping append."
else
  echo "→ Adding aliases block to $BASHRC"
  {
    echo ""
    echo "$ALIASES_MARKER"
    echo "alias k='kubectl'"
    echo "alias kgp='kubectl get pods'"
    echo "alias kgs='kubectl get svc'"
    echo "alias kgn='kubectl get nodes'"
    echo "alias kga='kubectl get all'"
    echo "alias kd='kubectl describe'"
    echo "alias kl='kubectl logs'"
    echo "alias kx='kubectl exec -it'"
    echo "alias kaf='kubectl apply -f'"
    echo "alias kdel='kubectl delete'"
    echo "alias kns='kubectl config set-context --current --namespace'"
    echo "alias h='helm'"
    echo "# Enable completion for the k alias (works once kubectl completion is sourced)."
    echo 'command -v kubectl >/dev/null && complete -o default -F __start_kubectl k'
    echo 'command -v helm    >/dev/null && complete -o default -F __start_helm    h'
    echo "# --- end aliases ---"
  } >> "$BASHRC"
fi

echo ""
echo "Done. Open a new shell, or run: source ~/.bashrc"
echo "Verify with: k <Tab><Tab>   kgp   kns kube-system"
