#!/usr/bin/env bash
# build.sh — generate PDF and HTML from ebook markdown files
#
# Requirements:
#   PDF:  pandoc + LaTeX (brew install pandoc && brew install --cask mactex)
#         OR pandoc + wkhtmltopdf (brew install pandoc wkhtmltopdf)
#   HTML: pandoc only
#
# Usage:
#   ./build.sh          — build both PDF and HTML
#   ./build.sh pdf      — PDF only
#   ./build.sh html     — HTML only
#   ./build.sh md       — concatenate all MD into single file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$SCRIPT_DIR/dist"
TITLE="Tailscale for AI Fleets"
AUTHORS="Mohinish Shaikh"
DATE="August 2026"

MD_FILES=(
  "$SCRIPT_DIR/00-cover.md"
  "$SCRIPT_DIR/01-preface.md"
  "$SCRIPT_DIR/02-toc.md"
  "$SCRIPT_DIR/03-chapter-01-introduction.md"
  "$SCRIPT_DIR/04-chapter-02-enroll-sparks.md"
  "$SCRIPT_DIR/05-chapter-03-acl-policy.md"
  "$SCRIPT_DIR/06-chapter-04-client-ssh.md"
  "$SCRIPT_DIR/07-cheatsheet.md"
  "$SCRIPT_DIR/08-troubleshooting.md"
)

mkdir -p "$OUT_DIR"

check_pandoc() {
  if ! command -v pandoc &>/dev/null; then
    echo "Error: pandoc not found. Install: brew install pandoc"
    exit 1
  fi
}

build_md() {
  echo "→ Building combined markdown..."
  local out="$OUT_DIR/tailscale-on-dgx-spark-bundle.md"
  {
    for f in "${MD_FILES[@]}"; do
      if [[ -f "$f" ]]; then
        cat "$f"
        printf "\n\n---\n\n"
      fi
    done
  } > "$out"
  echo "  ✓ $out"
}

build_pdf() {
  check_pandoc
  echo "→ Building PDF..."
  local out="$OUT_DIR/Ebook_Tailscale_on_DGX_Spark_Bundle.pdf"

  # Collect existing MD files only
  local existing=()
  for f in "${MD_FILES[@]}"; do
    [[ -f "$f" ]] && existing+=("$f")
  done

  if command -v xelatex &>/dev/null || command -v pdflatex &>/dev/null; then
    local latex_engine="xelatex"
    command -v xelatex &>/dev/null || latex_engine="pdflatex"

    pandoc "${existing[@]}" \
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
    local tmp_html="$OUT_DIR/tmp-for-pdf.html"
    pandoc "${existing[@]}" \
      --output="$tmp_html" \
      --metadata title="$TITLE" \
      --standalone \
      --toc \
      --toc-depth=2 \
      --highlight-style=tango \
      --css="$SCRIPT_DIR/styles.css"

    wkhtmltopdf \
      --title "$TITLE" \
      --margin-top 20 --margin-bottom 20 \
      --margin-left 20 --margin-right 20 \
      --footer-center "[page] of [topage]" \
      "$tmp_html" "$out"

    rm -f "$tmp_html"
  else
    echo "  ✗ No PDF engine found."
    echo "    Install: brew install --cask mactex   (xelatex — best quality)"
    echo "         or: brew install wkhtmltopdf     (lighter alternative)"
    return 1
  fi

  echo "  ✓ $out"
}

build_html() {
  check_pandoc
  echo "→ Building HTML..."

  if [[ -f "$SCRIPT_DIR/index.html" ]]; then
    cp "$SCRIPT_DIR/index.html" "$OUT_DIR/index.html"
    [[ -f "$SCRIPT_DIR/styles.css" ]] && cp "$SCRIPT_DIR/styles.css" "$OUT_DIR/styles.css"
    echo "  ✓ $OUT_DIR/index.html (pre-built SEO/AEO version)"
  fi

  local existing=()
  for f in "${MD_FILES[@]}"; do
    [[ -f "$f" ]] && existing+=("$f")
  done

  if [[ ${#existing[@]} -gt 0 ]]; then
    local pandoc_out="$OUT_DIR/tailscale-on-dgx-spark-bundle-pandoc.html"
    pandoc "${existing[@]}" \
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
      --metadata description="Step-by-step guide to enrolling NVIDIA DGX Spark machines onto a Tailscale tailnet with zero-trust SSH access control."
    echo "  ✓ $pandoc_out"
  fi
}

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
