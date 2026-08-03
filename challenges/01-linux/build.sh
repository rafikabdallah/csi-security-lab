#!/usr/bin/env bash
# Generates the Linux challenge archive from the flag in flags.env.
# Run from the repo root:  bash challenges/01-linux/build.sh
set -euo pipefail

# Resolve paths relative to this script, so it works from anywhere
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAGS_FILE="$SCRIPT_DIR/../flags.env"
DIST="$SCRIPT_DIR/dist"

# Load the flag
source "$FLAGS_FILE"
: "${FLAG_LINUX:?FLAG_LINUX not set in flags.env}"

# Fresh build workspace
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ROOT="$WORK/csi-linux"
mkdir -p "$ROOT/documents/archive" "$ROOT/.config/.cache"

# --- Decoy / misdirection files ---
cat > "$ROOT/README.txt" << 'TXT'
Welcome to the CSI Linux challenge.
Somewhere in this folder is a flag. Good luck.
Tip: not everything is visible at first glance.
TXT

cat > "$ROOT/documents/notes.txt" << 'TXT'
Shopping list:
- coffee
- ethernet cables
- a better password than "password123"
TXT

# A fake flag in an obvious place, to teach format-checking
echo "CSI{this_is_not_the_real_flag}" > "$ROOT/documents/archive/flag.txt"

# --- The real flag: hidden dir, hidden file ---
echo "$FLAG_LINUX" > "$ROOT/.config/.cache/.flag"

# A breadcrumb that rewards using ls -la
cat > "$ROOT/.config/hint" << 'TXT'
You found a hidden config directory. Keep looking deeper —
caches often hold things people forgot to clean up.
TXT

# --- Package it ---
mkdir -p "$DIST"
tar -czf "$DIST/linux-challenge.tar.gz" -C "$WORK" csi-linux
echo "Built: $DIST/linux-challenge.tar.gz"
