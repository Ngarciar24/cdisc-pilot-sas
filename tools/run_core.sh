#!/usr/bin/env bash
# Run CDISC CORE (open-source conformance rules) on a folder of SDTM XPT files,
# against SDTMIG 3.4 and CDISC CT 2026-03-27, the targets of this repo.
#
# Usage: tools/run_core.sh <xpt-folder> <report-basename> [encoding]
#   e.g. tools/run_core.sh data/sdtm outputs/qc/core_sdtm
#        tools/run_core.sh data/reference/sdtm /tmp/core_pilot cp1252
#
# Needs git, and uv (pip install uv) to get Python 3.12, which CORE requires.
# CORE is pinned to one commit; its bundled rules cache is used, so no CDISC
# Library API key is needed.
set -euo pipefail

DATA=$(realpath "$1")
OUT=$(realpath -m "$2")
ENCODING=${3:-utf-8}
CORE_SHA=3b330f06e3fb881dcba1e1965e9ad4543a2226a4
CORE_DIR=${CORE_DIR:-$HOME/.cache/cdisc-rules-engine}

if [ ! -d "$CORE_DIR/.git" ]; then
  git clone --filter=blob:none https://github.com/cdisc-org/cdisc-rules-engine "$CORE_DIR"
fi
git -C "$CORE_DIR" fetch -q origin "$CORE_SHA" || true
git -C "$CORE_DIR" checkout -q "$CORE_SHA"

if [ ! -x "$CORE_DIR/.venv/bin/python" ]; then
  uv venv -q -p 3.12 "$CORE_DIR/.venv"
  uv pip install -q -p "$CORE_DIR/.venv/bin/python" -e "$CORE_DIR"
fi

cd "$CORE_DIR"
.venv/bin/python core.py validate -s sdtmig -v 3-4 -ct sdtmct-2026-03-27 \
  -d "$DATA" -e "$ENCODING" -o "$OUT" -of json -p disabled -l error
echo "CORE report: $OUT.json"
