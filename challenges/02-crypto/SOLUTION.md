# Solution — Cryptography: Layers

**Flag:** stored in `challenges/flags.env` as `FLAG_CRYPTO` (not committed).

## Encoding chain

The challenge is built by applying, in order:
1. ROT13 to the flag
2. Base64 encoding of that result

The player therefore undoes it in reverse: Base64 decode, then ROT13.

## Intended solve path

### Command line
```bash
cat cipher.txt | base64 -d | tr 'A-Za-z' 'N-ZA-Mn-za-m'
# CSI{classical_ciphers_still_teach}
```

- `base64 -d` decodes the outer layer.
- `tr 'A-Za-z' 'N-ZA-Mn-za-m'` applies ROT13. ROT13 is self-inverse, so the
  same command both scrambles and unscrambles.

### Browser alternative (CyberChef)
Load cipher.txt content, then apply the recipe:
`From Base64` -> `ROT13`. The "Magic" operation also auto-detects both.

## Recognition clues taught

- Trailing `=` padding and the `A-Za-z0-9+/` alphabet = Base64.
- Output that looks like shifted English = a Caesar/ROT cipher.

## Concepts taught

- Base64 encoding vs. encryption (encoding is not security)
- ROT13 / Caesar cipher and its self-inverse property
- Chained transformations: identify each layer before decoding the next
- Command-line tools (base64, tr) and CyberChef
