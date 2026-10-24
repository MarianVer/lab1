#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if [ ! -f ".venv/bin/python" ] && [ ! -f ".venv/Scripts/python.exe" ]; then
  rm -rf .venv
  python3 -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install pytest
python -m pytest -q
