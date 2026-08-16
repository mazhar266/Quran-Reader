#!/usr/bin/env bash
# Refresh the bundled Quran data and surah index from the QQ-Lang checkout.
#
# The assets mirror QQ-Lang's `sources/` layout exactly, because QuranRepository
# unpacks them verbatim and QQL resolves paths relative to that root. Bump
# _dataVersion in lib/src/data/quran_repository.dart after running this, or
# existing installs will keep their old copy.
#
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QQL_DIR="${QQL_DIR:-$HOME/Projects/QQ Lang}"
CHAPTERS="$QQL_DIR/sources/quran-json-arabic/dist/chapters"

if [[ ! -d "$CHAPTERS/en" ]]; then
  echo "Quran data not found at '$CHAPTERS/en'." >&2
  echo "Run 'git submodule update --init' in the QQ-Lang checkout." >&2
  exit 1
fi

DEST="$APP_DIR/assets/qqldata/quran-json-arabic/dist/chapters/en"
rm -rf "$DEST"
mkdir -p "$DEST"
cp "$CHAPTERS"/en/*.json "$DEST/"
cp "$CHAPTERS/index.json" "$APP_DIR/assets/surah_index.json"

echo "Synced $(ls "$DEST" | wc -l) chapter files ($(du -sh "$DEST" | cut -f1))."
