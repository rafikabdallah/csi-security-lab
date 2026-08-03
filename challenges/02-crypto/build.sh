#!/usr/bin/env bash
# Generates the crypto challenge from the flag in flags.env.
# Player solve path: base64 decode -> ROT13 -> flag
# Build path (reverse): flag -> ROT13 -> base64 encode
# Run from repo root:  bash challenges/02-crypto/build.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAGS_FILE="$SCRIPT_DIR/../flags.env"
DIST="$SCRIPT_DIR/dist"

source "$FLAGS_FILE"
: "${FLAG_CRYPTO:?FLAG_CRYPTO not set in flags.env}"

mkdir -p "$DIST"

# 1) ROT13 the flag (tr rotates letters by 13; digits/braces/underscore untouched)
rot13() { tr 'A-Za-z' 'N-ZA-Mn-za-m'; }

# 2) Encode the ROT13 output as Base64 -> this is what the player receives
printf '%s' "$FLAG_CRYPTO" | rot13 | base64 > "$DIST/cipher.txt"

echo "Built: $DIST/cipher.txt"
echo "Preview (what the player sees):"
cat "$DIST/cipher.txt"
