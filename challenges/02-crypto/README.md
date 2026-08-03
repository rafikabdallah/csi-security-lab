# Cryptography — Layers

**Category:** Cryptography
**Difficulty:** Easy / Medium
**Points:** 75

## Description

We intercepted a message, but it doesn't look like much — just a block of
letters, numbers, and a couple of `=` signs at the end. It's not encrypted
with anything unbreakable. It's just wearing a few disguises.

Peel back the layers to reveal the flag.

## Hints

1. Those `=` signs at the end are a strong clue about the outermost layer.
   What encoding pads its output with `=`? (Cost: 5 pts)
2. Decoding the first layer gives you text that looks almost like words but
   isn't quite. A very famous, very simple letter-rotation cipher is
   hiding underneath. (Cost: 10 pts)

## Files

- `cipher.txt`

## Flag format

`CSI{...}`
