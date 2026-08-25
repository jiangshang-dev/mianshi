#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/entry/src/docs"
DST="$ROOT/entry/src/main/resources/rawfile/docs"
mkdir -p "$DST"
rsync -a --delete --include='*/' --include='*.md' --exclude='*' \
  --exclude='snippets/' "$SRC/" "$DST/"
rm -rf "$DST/snippets" "$DST/about-the-author" "$DST/javaguide" "$DST/books" 2>/dev/null || true
python3 "$ROOT/scripts/generate_doc_catalog.py"
echo "synced docs -> rawfile and regenerated DocCatalog.json"
