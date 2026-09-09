#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Reproducible headless checks; no GitHub native-binary download is required.
# Prerequisites: Node.js 22+, npm; Python 3.10+ for place/audio tooling.
npm ci --prefix scripts --ignore-scripts
printf '\nNext: npm test --prefix scripts\nThen: python3 scripts/build-place.py --check\nStudio playtesting remains a separate required step.\n'
