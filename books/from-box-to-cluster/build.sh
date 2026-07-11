#!/usr/bin/env bash
# build.sh — generate PDF and HTML from ebook markdown files
#
# Requirements:
#   PDF:  pandoc + LaTeX (install: brew install pandoc && brew install --cask mactex)
#         OR pandoc + wkhtmltopdf (lighter: brew install pandoc wkhtmltopdf)
#   HTML: pandoc only (already available if you have pandoc)
#
# Usage:
#   ./build.sh          — build both PDF and HTML
#   ./build.sh pdf      — PDF only
#   ./build.sh html     — HTML only
#   ./build.sh md       — concatenate all MD into single file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$SCRIPT_DIR/dist"
TITLE="From Box to Cluster"
AUTHORS="Mohinish Shaikh, Sanwi Sarode"
DATE="July 2026"

# Ordered list of source markdown files
MD_FILES=(
  "$SCRIPT_DIR/00-cover.md"
  "$SCRIPT_DIR/01-preface.md"
  "$SCRIPT_DIR/02-toc.md"
  "$SCRIPT_DIR/03-chapter-01-introduction.md"
  "$SCRIPT_DIR/04-chapter-02-hardware-setup.md"
  "$SCRIPT_DIR/05-chapter-03-cuda-updates.md"
  "$SCRIPT_DIR/06-chapter-04-k3s-setup.md"
  "$SCRIPT_DIR/07-chapter-05-kuberay-setup.md"
  "$SCRIPT_DIR/08-chapter-06-vllm-setup.md"
  "$SCRIPT_DIR/09-chapter-07-aibrix-setup.md"
  "$SCRIPT_DIR/10-chapter-08-cluster-setup.md"
  "$SCRIPT_DIR/12-chapter-09-system-architecture.md"
  "$SCRIPT_DIR/13-back-page.md"
)

mkdir -p "$OUT_DIR"

#──────────────────────────────────────────────────────────────────────────────
# Helpers
#──────────────────────────────────────────────────────────────────────────────

check_pandoc() {
  if ! command -v pandoc &>/dev/null; then
    echo "Error: pandoc not found."
    echo "Install: brew install pandoc"
    exit 1
  fi
}

#──────────────────────────────────────────────────────────────────────────────
# Single combined markdown
#──────────────────────────────────────────────────────────────────────────────

build_md() {
  echo "→ Building combined markdown..."
  local out="$OUT_DIR/dgx-spark-ebook.md"
  {
    for f in "${MD_FILES[@]}"; do
      cat "$f"
      printf "\n\n---\n\n"
    done
  } > "$out"
  echo "  ✓ $out"
}

#──────────────────────────────────────────────────────────────────────────────
# PDF via pandoc → LaTeX → PDF (best quality)
#──────────────────────────────────────────────────────────────────────────────

build_pdf() {
  check_pandoc
  echo "→ Building PDF..."

  local out="$OUT_DIR/dgx-spark-ebook.pdf"

  # Try pdflatex first (best output), fall back to wkhtmltopdf
  if command -v pdflatex &>/dev/null || command -v xelatex &>/dev/null; then
    local latex_engine="xelatex"
    command -v xelatex &>/dev/null || latex_engine="pdflatex"

    pandoc "${MD_FILES[@]}" \
      --output="$out" \
      --pdf-engine="$latex_engine" \
      --metadata title="$TITLE" \
      --metadata author="$AUTHORS" \
      --metadata date="$DATE" \
      --metadata lang="en-US" \
      --variable geometry:margin=1in \
      --variable fontsize=11pt \
      --variable colorlinks=true \
      --variable linkcolor=NavyBlue \
      --variable urlcolor=NavyBlue \
      --variable toccolor=NavyBlue \
      --toc \
      --toc-depth=2 \
      --number-sections \
      --highlight-style=tango \
      --standalone

  elif command -v wkhtmltopdf &>/dev/null; then
    # Intermediate HTML then wkhtmltopdf
    local tmp_html="$OUT_DIR/tmp-for-pdf.html"
    pandoc "${MD_FILES[@]}" \
      --output="$tmp_html" \
      --metadata title="$TITLE" \
      --standalone \
      --toc \
      --toc-depth=2 \
      --highlight-style=tango \
      --css="$SCRIPT_DIR/styles.css"

    wkhtmltopdf \
      --title "$TITLE" \
      --margin-top 20 \
      --margin-bottom 20 \
      --margin-left 20 \
      --margin-right 20 \
      --footer-center "[page] of [topage]" \
      "$tmp_html" "$out"

    rm -f "$tmp_html"
  else
    echo "  ✗ No PDF engine found."
    echo "    Install one of:"
    echo "      brew install --cask mactex          (for xelatex — best quality)"
    echo "      brew install wkhtmltopdf            (lighter alternative)"
    return 1
  fi

  echo "  ✓ $out"
}

#──────────────────────────────────────────────────────────────────────────────
# HTML — standalone webpage (uses pre-built index.html, or generates via pandoc)
#──────────────────────────────────────────────────────────────────────────────

build_html() {
  check_pandoc
  echo "→ Building HTML..."

  # The full index.html is hand-crafted with SEO/AEO markup.
  # Copy it and the stylesheet to dist/.
  if [[ -f "$SCRIPT_DIR/index.html" ]]; then
    cp "$SCRIPT_DIR/index.html" "$OUT_DIR/index.html"
    [[ -f "$SCRIPT_DIR/styles.css" ]] && cp "$SCRIPT_DIR/styles.css" "$OUT_DIR/styles.css"
    echo "  ✓ $OUT_DIR/index.html (pre-built SEO/AEO version)"
  fi

  # Also generate a pandoc HTML version as a simpler alternative
  local pandoc_out="$OUT_DIR/dgx-spark-ebook-pandoc.html"
  pandoc "${MD_FILES[@]}" \
    --output="$pandoc_out" \
    --metadata title="$TITLE" \
    --metadata author="$AUTHORS" \
    --metadata date="$DATE" \
    --standalone \
    --toc \
    --toc-depth=2 \
    --number-sections \
    --highlight-style=tango \
    --css="styles.css" \
    --metadata description="Step-by-step guide to configuring the NVIDIA DGX Spark Bundle into a 2-node AI supercomputer cluster running vLLM, KubeRay, k3s, and AIBrix."

  echo "  ✓ $pandoc_out (pandoc-generated version)"
}

#──────────────────────────────────────────────────────────────────────────────
# Main
#──────────────────────────────────────────────────────────────────────────────

TARGET="${1:-all}"

case "$TARGET" in
  pdf)   build_pdf ;;
  html)  build_html ;;
  md)    build_md ;;
  all)
    build_md
    build_html
    build_pdf
    ;;
  *)
    echo "Usage: $0 [all|pdf|html|md]"
    exit 1
    ;;
esac

echo ""
echo "Output files in: $OUT_DIR/"
ls -lh "$OUT_DIR/" 2>/dev/null || true
