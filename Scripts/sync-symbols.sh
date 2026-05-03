#!/usr/bin/env bash
# Refresh Vendor/open-symbols from the upstream buzap/open-symbols repository.
# Vendor/ is gitignored; this script is the source of truth for what gets
# bundled into our generated targets.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/Vendor/open-symbols"
UPSTREAM="https://github.com/buzap/open-symbols.git"

mkdir -p "$ROOT/Vendor"

if [ -d "$VENDOR/.git" ]; then
    echo "Updating $VENDOR..."
    git -C "$VENDOR" fetch --depth 1 origin
    git -C "$VENDOR" reset --hard origin/HEAD
else
    echo "Cloning $UPSTREAM into $VENDOR..."
    rm -rf "$VENDOR"
    git clone --depth 1 "$UPSTREAM" "$VENDOR"
fi

echo "Done. Run Scripts/generate.py to regenerate Sources/."
