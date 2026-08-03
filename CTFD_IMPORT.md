# CTFd Import Template

`ctfd-template.zip` is a **sanitized** CTFd export. It lets you load all four
challenges — names, descriptions, categories, point values, and hints — in one
click, instead of recreating them by hand in the admin panel.

## What it contains

- All 4 challenge definitions (Linux, Cryptography, Packet Analysis, Log Analysis)
- Their descriptions, point values, and hints
- The site pages and theme config
- The branding images (logo, banner, icon)

## What it does NOT contain (by design)

- **No flags.** Every flag is blanked to `CSI{REPLACE_ME}`. You set the real
  flags after import.
- **No accounts, emails, or password hashes.** You create your own admin via the
  setup wizard.
- **No challenge files.** The `.pcap`, `auth.log`, `cipher.txt`, and
  `.tar.gz` are not included — you regenerate them with the `build.sh` scripts
  (they contain flags, so they are never shipped).

## How to use it

1. Deploy CTFd (`docker compose up -d`) and complete the setup wizard to create
   your admin account.
2. Generate the challenge files with your own flags:
   ```bash
   # after creating challenges/flags.env with your flags
   bash challenges/01-linux/build.sh
   bash challenges/02-crypto/build.sh
   bash challenges/03-packet-analysis/build.sh
   bash challenges/04-log-analysis/build.sh
   ```
3. In CTFd: **Admin Panel → Config → Backup → Import**, and upload
   `ctfd-template.zip`. This creates all four challenges.
4. For each challenge, edit it in the admin panel to:
   - Set the real **flag** (replace `CSI{REPLACE_ME}` with the value from your
     `challenges/flags.env`).
   - Upload the generated file from the challenge's `dist/` folder.
5. Make the challenges visible. Done.

> The flag and file steps are manual on purpose: shipping either one would leak
> answers into the public repository. The template gets you ~90% of the setup;
> you supply the secret 10%.
