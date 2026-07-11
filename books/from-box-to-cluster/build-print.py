#!/usr/bin/env python3
"""Assemble dist/print.html from individual book pages for PDF generation."""

import re
import os

HERE = os.path.dirname(os.path.abspath(__file__))
DIST = os.path.join(HERE, "dist")

PAGES = [
    "index.html",        # cover + preface + TOC
    "chapter-01.html",
    "chapter-02.html",
    "chapter-03.html",
    "chapter-04.html",
    "chapter-05.html",
    "chapter-06.html",
    "chapter-07.html",
    "chapter-08.html",
    "cheatsheet.html",
    "troubleshooting.html",
    "faq.html",
    "authors.html",
]

def extract_main(path):
    with open(path, encoding="utf-8") as f:
        html = f.read()
    m = re.search(r'<main[^>]*id="main-content"[^>]*>(.*)</main>', html, re.DOTALL)
    return m.group(1).strip() if m else ""

PRINT_HTML_HEAD = """\
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>From Box to Cluster: Building a Personal AI Supercomputer with NVIDIA DGX Spark Bundle</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="../styles.css">
  <style>
    @page { size: letter; margin: 0.9in 0.85in; }
    body { font-size: 13px; line-height: 1.65; }
    .sidebar, .sidebar-overlay, .topbar, .skip-link,
    .btn-download, .chapter-nav, .nav-btn-label, .nav-btn-title,
    footer { display: none !important; }
    .main { margin-left: 0 !important; }
    .pdf-break { page-break-before: always; break-before: page; }
    .cover-section { min-height: 96vh; page-break-after: always; break-after: page; }
    pre { page-break-inside: avoid; break-inside: avoid; }
    h1, h2, h3 { page-break-after: avoid; break-after: avoid; }
    .callout { page-break-inside: avoid; break-inside: avoid; }
    table { page-break-inside: avoid; break-inside: avoid; }
    .content-area { padding: 0 0 40px; }
    .chapter-section { padding-top: 8px; }
    figure svg { max-width: 100% !important; }
  </style>
</head>
<body>
<div class="main">
"""

PRINT_HTML_FOOT = """
</div>
</body>
</html>
"""

def main():
    os.makedirs(DIST, exist_ok=True)
    sections = []

    for i, filename in enumerate(PAGES):
        path = os.path.join(HERE, filename)
        content = extract_main(path)
        if not content:
            print(f"  WARNING: no <main> found in {filename}")
            continue

        if i == 0:
            # First page (cover + front matter) — no page break before
            sections.append(content)
        else:
            # Every subsequent page starts on a new page
            sections.append(f'<div class="pdf-break"></div>\n{content}')

        print(f"  + {filename}")

    full = PRINT_HTML_HEAD + "\n\n".join(sections) + PRINT_HTML_FOOT

    out = os.path.join(DIST, "print.html")
    with open(out, "w", encoding="utf-8") as f:
        f.write(full)

    print(f"\nWrote {out} ({len(full):,} bytes)")

if __name__ == "__main__":
    main()
