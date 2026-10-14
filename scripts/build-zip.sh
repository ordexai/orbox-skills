#!/usr/bin/env bash
# Builds dist/orbox-process.zip with orbox-process/ at the archive root, as the claude.ai skill upload expects.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
rm -rf "$root/dist" && mkdir -p "$root/dist"
cd "$root/skills"
zip -qr -X "$root/dist/orbox-process.zip" orbox-process -x '*.DS_Store'
echo "$root/dist/orbox-process.zip"
