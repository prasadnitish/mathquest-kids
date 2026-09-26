#!/usr/bin/env bash
# Downloads the latest filmed footage (published by the "Promo capture" workflow to the
# promo-footage branch) into public/footage and indexes it for the compositions.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMO="$(cd "$HERE/.." && pwd)"
git -C "$PROMO" fetch -q origin promo-footage
rm -rf "$PROMO/public/footage"
mkdir -p "$PROMO/public/footage"
git -C "$PROMO" archive origin/promo-footage | tar -x -C "$PROMO/public/footage"
python3 "$HERE/index_footage.py"
