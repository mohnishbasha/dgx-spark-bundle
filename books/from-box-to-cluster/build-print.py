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
    content = m.group(1).strip() if m else ""
    # Open all <details> elements so FAQ answers are visible in the PDF
    content = re.sub(r'<details(?!\s+open)', '<details open', content)
    return content

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
    /* ── Page setup ── */
    @page { size: letter; margin: 0.85in 0.9in; }
    body { font-size: 11pt; line-height: 1.55; }

    /* ── Hide web chrome ── */
    .sidebar, .sidebar-overlay, .topbar, .skip-link,
    .btn-download, .chapter-nav, .nav-btn-label, .nav-btn-title,
    footer { display: none !important; }

    /* ── Layout reset ── */
    .main { margin-left: 0 !important; }
    .layout { display: block; }
    .content-area { max-width: 100%; padding: 0 0 16px !important; margin: 0 auto; }

    /* ── Cover: single clean page ── */
    .cover-section {
      padding: 48px 20px 36px !important;
      min-height: 0 !important;
      page-break-after: always;
      break-after: page;
    }
    .orb { display: none !important; }
    .gradient-bg { background: #f0fdf4 !important; animation: none !important; }
    .cover-title { font-size: 26pt !important; }
    .cover-subtitle { font-size: 12pt !important; }

    /* ── Page breaks between chapters only ── */
    .pdf-break { page-break-before: always; break-before: page; }

    /* ── Compact headings and spacing ── */
    .chapter-section { padding-top: 2px !important; }
    h1 { font-size: 20pt !important; margin-bottom: 8px !important; }
    h2 { font-size: 14pt !important; margin: 16px 0 8px !important;
         padding-bottom: 4px !important;
         page-break-before: avoid !important; break-before: avoid !important; }
    h3 { font-size: 12pt !important; margin: 12px 0 6px !important; }
    h4 { font-size: 11pt !important; margin: 8px 0 4px !important; }
    p  { margin-bottom: 8px !important; }
    h1, h2, h3, h4 { page-break-after: avoid; break-after: avoid; }

    /* ── Code ── */
    pre {
      font-size: 8.5pt !important; line-height: 1.4 !important;
      padding: 10px 14px !important; margin: 8px 0 !important;
      page-break-inside: avoid; break-inside: avoid;
      white-space: pre-wrap; word-break: break-word;
    }

    /* ── Tables ── */
    table { font-size: 10pt !important; box-shadow: none !important;
            page-break-inside: avoid; break-inside: avoid; }
    th, td { padding: 6px 10px !important; }

    /* ── Callouts ── */
    .callout { margin: 8px 0 !important; page-break-inside: avoid; break-inside: avoid; }

    /* ── Stack cards ── */
    .stack-grid { grid-template-columns: 1fr 1fr !important; gap: 8px !important; margin: 12px 0 !important; }
    .stack-card { box-shadow: none !important; padding: 12px !important; break-inside: avoid; }

    /* ── FAQ: force answers open ── */
    .faq-answer { display: block !important; }
    .faq-chevron { display: none !important; }
    .faq-item { box-shadow: none !important; }

    /* ── Figures / SVG ── */
    figure { page-break-inside: avoid; break-inside: avoid; margin: 10px 0 !important; }
    figure svg { max-width: 100% !important; width: 100% !important; }
    figcaption { font-size: 9pt !important; margin-top: 4px !important; }

    /* ── Preserve colors in print ── */
    * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
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
