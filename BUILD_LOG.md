# Build Log

A phase-by-phase record of the rebuild, including decisions made and problems
hit. This is a scoped **rebuild** — a first version existed but its files were
lost (see the data-loss note in ARCHITECTURE.md). Scope was held deliberately
tight: exactly four challenges, one per category, no feature creep.

---

## Phase 1 — VM, Docker, Docker Compose

**Status:** Complete

- Reused the existing `csi-server` Ubuntu Server 24.04 VM (VMware, NAT
  networking, static IP `192.168.119.50`, SSH from the Windows host). This lab
  was already built and documented for a previous project, so no new VM was
  provisioned.
- Installed Docker Engine and the Docker Compose **plugin** (`docker compose`,
  the current standard) from Docker's official apt repository.
- Added the user to the `docker` group to avoid `sudo` on every command.
- Opened port `8000/tcp` in `ufw` (default-deny-incoming policy already in
  place from the lab baseline).
- Created the project directory and ran `git init` before writing any project
  files, so history reflects the whole build.

**Decision:** use the Compose *plugin*, not the deprecated standalone
`docker-compose`.

---

## Phase 2 — CTFd via Docker Compose

**Status:** Complete

- Cloned the official CTFd repo only to extract its reference
  `docker-compose.yml`, then deleted the clone — the repo does not need CTFd's
  source, only the compose pattern and the prebuilt image.
- Adapted the reference compose file:
  - `build: .` → `image: ctfd/ctfd:3.8.6` (pinned prebuilt official image).
  - Removed the `nginx` reverse-proxy service; set `REVERSE_PROXY=false`.
  - Replaced hardcoded `ctfd`/`ctfd` credentials with `${VARIABLE}` references
    resolved from a gitignored `.env`.
  - Added an explicit `CTFD_SECRET_KEY` rather than relying on CTFd's
    auto-generated one, for reproducibility.
- Generated three independent 32-byte secrets (`DB_ROOT_PASSWORD`,
  `DB_PASSWORD`, `CTFD_SECRET_KEY`) with `secrets.token_hex(32)`.
- Wrote `.gitignore` (`.env`, `.data/`, `ctfd-src/`, `challenges/flags.env`,
  `challenges/**/dist/`) **before** any secret file existed, then confirmed via
  `git status` that no secret was ever staged.
- Brought the stack up: `ctfd`, `db`, `cache` running; `permissions` one-shot
  container exits 0 as expected. Verified CTFd migrated the database and started
  gunicorn cleanly.
- Completed the setup wizard: **User mode**, Challenge visibility Private,
  Score/Account/Registration Public, email verification **Disabled** (no SMTP
  configured).

**Decisions:**
- Pin the image tag rather than track `latest`, for reproducibility.
- Drop nginx to reduce moving parts; documented as a production upgrade in
  ARCHITECTURE.md.
- Two separate secret files (infra vs. flags) because they have different
  consumers and lifecycles.

**Blocker hit:** an SSH session dropped mid-phase, and one command was
accidentally run in Windows PowerShell instead of on the VM. Caught immediately;
no damage, nothing had been written yet. Reconnected and continued.

---

## Phase 3 — Challenge files

**Status:** Complete

All four challenges follow the same pattern: a `build.sh` reads the flag from
`challenges/flags.env` and generates the player-facing file into `dist/`. The
generated file is gitignored; the script is committed.

- **01 Linux — "Hidden in Plain Sight"** (Easy, 50 pts). A `.tar.gz` that
  extracts to a small tree with a hidden `.config/.cache/.flag`, a breadcrumb
  hint file, and a fake flag as a decoy to teach format-checking. Verified the
  intended `ls -la` → navigate → `cat` path reaches the real flag.
- **02 Crypto — "Layers"** (Easy/Medium, 75 pts). A Base64 → ROT13 chain. The
  build script applies the transforms in reverse (ROT13 then Base64-encode).
  Verified `base64 -d | tr` returns the flag.
- **03 Packet Analysis — "Clear Text"** (Easy/Medium, 100 pts). A Scapy-forged
  pcap containing a full TCP handshake and a plaintext HTTP POST whose body
  carries the flag, plus decoy traffic. Verified the flag is recoverable via
  Wireshark "Follow HTTP Stream" (and via `strings`).
- **04 Log Analysis — "Who Got In"** (Medium, 100 pts). A synthetic `auth.log`
  with ~14 `Failed password` entries from one attacker IP followed by a single
  `Accepted password`. The flag **is** the attacker IP. The script generates a
  random IP, writes the log, and updates `FLAG_LOG` in `flags.env` so the CTFd
  answer stays in sync. Verified via `grep | sort | uniq -c` that the attacker
  IP dominates and the compromise line confirms it.

**Decision:** for the log challenge, make the flag a *finding* (the attacker IP)
rather than a planted string, so the challenge mirrors real incident response.
Trade-off: `FLAG_LOG` is managed by the build script instead of hand-fixed like
the other three — accepted for realism and reproducibility.

**Note:** Scapy prints `getmacbyip` warnings when forging packets for
non-existent IPs; harmless, the fake Ethernet layer is irrelevant to the
challenge.

---

## Phase 4 — Load challenges into CTFd

**Status:** Complete

- Created each challenge as `standard` type via the admin panel: name,
  category, description, points, case-sensitive flag, two hints with costs, and
  the uploaded file.
- Transferred the generated files from the VM to the Windows host with `scp`
  (browser uploads can only read from the host filesystem).
- Registered a separate non-admin `tester` account and solved a challenge
  end-to-end to confirm flag submission scores correctly and wrong flags are
  rejected.

**Decision:** keep the `tester` solve for a populated scoreboard in
screenshots; note it can be purged before real use.

---

## Phase 5 — Branding, documentation, screenshots

**Status:** Complete

- Generated original branding (logo, banner, favicon) in the CSI blue/green
  palette and applied them via the CTFd Style config. (These are original
  assets for the platform, not the club's official logo.)
- Applied a dark-navy theme via the CTFd Theme Header (custom CSS): navy
  background, blue challenge cards stacked vertically per category, green
  reserved for solved challenges, themed nav bar and challenge modal.
- Rewrote the homepage (`index` page) with a branded intro and four category
  cards matching the theme.
- Wrote README.md, ARCHITECTURE.md, and this BUILD_LOG.md.
- Captured screenshots: homepage, challenges page, challenge modal, scoreboard.

**Decision:** timebox visual polish. Theme via the built-in Primary Color and
Theme Header only — no third-party theme, which would have broken
reproducibility. Prioritized documentation over adding more challenges, because
a documented, pushed 4-challenge CTF is worth more than an undocumented larger
one.

---

## Phase 6 — Push

**Status:** In progress

- Create the public GitHub repository and push. Local commits were made
  throughout; the repo had not been pushed to GitHub until this phase.

---

## Key decisions at a glance

| Decision | Choice | Why |
|---|---|---|
| CTF platform | CTFd (not custom) | Industry standard; focus effort on content |
| Image tag | Pinned `3.8.6` | Reproducibility over auto-updates |
| Reverse proxy | Dropped nginx | Scope cut; documented upgrade path |
| Challenge delivery | Static files | Zero player-code execution on host |
| Secrets | Two gitignored `.env` files | Infra vs. flags; never in git |
| Log challenge flag | Attacker IP (a finding) | Mirrors real incident response |
| Theming | Built-in CSS only | No third-party theme; keep it reproducible |
| Priority under deadline | Docs before extra challenges | Unpushed work does not exist |
