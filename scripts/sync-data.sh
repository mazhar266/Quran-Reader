#!/usr/bin/env bash
# Refresh the bundled Quran data from the QQ-Lang checkout.
#
# The assets mirror QQ-Lang's `sources/` layout exactly, because QuranRepository
# unpacks them verbatim and QQL resolves paths relative to that root. Bump
# _dataVersion in lib/src/data/quran_repository.dart after running this, or
# existing installs will keep their old copy.
#
# The surah index is derived here rather than copied: the dataset has no
# index.json, but every chapter file carries the metadata the list needs.
#
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QQL_DIR="${QQL_DIR:-$HOME/Projects/QQ Lang}"
SRC="$QQL_DIR/sources/quran"

if [[ ! -d "$SRC/chapters" ]]; then
  echo "Quran data not found at '$SRC/chapters'." >&2
  echo "Run 'git submodule update --init' in the QQ-Lang checkout." >&2
  exit 1
fi

DEST="$APP_DIR/assets/qqldata/quran"
rm -rf "$APP_DIR/assets/qqldata"
mkdir -p "$DEST/chapters"
cp "$SRC"/chapters/*.json "$DEST/chapters/"
# The Tanzil licence requires its copyright block to travel with the text.
cp "$SRC/TANZIL-LICENSE.txt" "$DEST/"

python3 - "$DEST/chapters" "$APP_DIR/assets/surah_index.json" <<'PY'
import json, sys, pathlib
src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
index = []
for f in src.glob('*.json'):
    d = json.loads(f.read_text())
    index.append({k: d[k] for k in
                  ('id', 'name', 'transliteration', 'type', 'total_verses')})
index.sort(key=lambda c: c['id'])
assert len(index) == 114, f'expected 114 surahs, got {len(index)}'
out.write_text(json.dumps(index, ensure_ascii=False))
print(f'  index: {len(index)} surahs')
PY

echo "Synced $(ls "$DEST/chapters" | wc -l) chapter files ($(du -sh "$DEST" | cut -f1))."
