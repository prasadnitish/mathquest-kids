#!/usr/bin/env bash
# Downloads the latest filmed footage (published by the "Promo capture" workflow to the
# promo-footage branch) into public/footage and indexes it for the compositions.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMO="$(cd "$HERE/.." && pwd)"
git -C "$PROMO" fetch -q origin promo-footage
rm -rf "$PROMO/public/footage"
mkdir -p "$PROMO/public/footage"
# From the repository root: run inside promo/, git archive would keep only promo/ paths.
ROOT="$(git -C "$PROMO" rev-parse --show-toplevel)"
git -C "$ROOT" archive origin/promo-footage | tar -x -C "$PROMO/public/footage"
python3 "$HERE/index_footage.py"
