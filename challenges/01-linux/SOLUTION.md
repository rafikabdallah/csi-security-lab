# Solution — Linux: Hidden in Plain Sight

**Flag:** stored in `challenges/flags.env` as `FLAG_LINUX` (not committed).

## Intended solve path

1. Extract the archive:
```bash
   tar -xzf linux-challenge.tar.gz
   cd csi-linux
```

2. A plain listing looks almost empty:
```bash
   ls
   # README.txt  documents
```

3. List hidden entries with `-a`:
```bash
   ls -la
   # reveals .config
```

4. Explore the hidden config directory. A `hint` file points toward caches:
```bash
   cat .config/hint
   ls -la .config
   # reveals .cache
```

5. The cache holds a hidden flag file:
```bash
   ls -la .config/.cache
   cat .config/.cache/.flag
   # CSI{hidden_files_never_lie}
```

## Decoys / learning points

- documents/archive/flag.txt contains a fake flag to teach players to
  verify rather than submit the first match.
- Reinforces that a leading dot only hides a file from casual listing.

## Concepts taught

- Hidden files and directories (dotfiles)
- ls -la, cat, cd
- Verifying flag format before submission
