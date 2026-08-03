# Architecture & Design Decisions

This document explains *why* the CSI Security Lab is built the way it is. It is
written for two audiences: a technical reviewer who wants to judge the
engineering, and a recruiter who wants to understand the reasoning behind the
choices.

---

## 1. Why CTFd instead of a custom platform

A CTF platform needs user registration, authentication, session management,
password hashing, a scoreboard, flag submission with rate-limiting, hint
unlocking, file hosting, and an admin panel. Building all of that from scratch
would be a **web-development project**, not a security project — and any
authentication bug written by hand would be a vulnerability in a platform whose
entire purpose is to teach security.

CTFd was chosen because:

- It is the **industry-standard** open-source CTF framework, used by large
  public CTFs and university clubs. Reviewers recognize it immediately.
- It is battle-tested. Re-implementing auth, scoring, and rate-limiting badly
  is a real risk that CTFd removes.
- It frees the build effort to focus on **the actual security content** —
  designing challenges, forging packet captures, generating realistic logs —
  which is where the cybersecurity value lives.

The engineering contribution here is not "I wrote a CTF platform." It is
"I selected, deployed, configured, hardened, and extended an existing platform"
— which is what operational security and systems work actually looks like.

---

## 2. Why Docker + Docker Compose

Docker was chosen for three reasons, in order of importance:

**Reproducibility.** The project's bar is: a clean VM plus `git clone` plus
`docker compose up` must produce a working platform. Docker makes that literal.
A reviewer can reproduce the entire environment in minutes without manually
installing Python, MariaDB, Redis, and a WSGI server. If it is not reproducible,
it is not a portfolio piece.

**Isolation.** Each service (CTFd, database, cache) runs in its own container
with its own filesystem and network namespace. A problem in one does not
directly compromise the others or the host.

**Clean teardown.** `docker compose down -v` removes the entire stack. Nothing
is left scattered across the host OS.

### Service layout

| Service | Image | Role | Network |
|---|---|---|---|
| `ctfd` | `ctfd/ctfd:3.8.6` | Web application (port 8000) | default + internal |
| `db` | `mariadb:10.11` | Persistent data store | internal only |
| `cache` | `redis:4` | Session / cache backend | internal only |
| `permissions` | `alpine:3.23` | One-shot: fixes volume ownership, then exits | — |

The image tag is **pinned** (`3.8.6`, not `latest`) so that a future
`docker compose up` produces the same version a reviewer sees today. `latest`
would silently drift.

### Network segmentation

Two Docker networks are defined:

- `default` — reachable from the host; only the `ctfd` service is attached to it.
- `internal` — declared `internal: true`, meaning it has **no route to the
  outside**. MariaDB and Redis live here.

The result: the database and cache are **not reachable from the host or the
network at all**. Only CTFd can talk to them, and only CTFd is exposed. This is
network segmentation at the container level — the same principle as isolating a
database tier behind an application tier in a real deployment.

---

## 3. Why challenges are static files (not live containers)

Per-challenge live containers were explicitly cut from scope. This is a
deliberate trade-off, and it has a genuine security upside.

Because challenges are delivered as **downloadable static files** that players
solve on their own machines, the player **never executes anything on the
platform host**. There is no challenge-container attack surface, no risk of a
player breaking out of a challenge sandbox into the host, and no orchestration
complexity. For a beginner teaching platform, this is not a limitation — it is
the safer design.

The trade-off: challenge types that *require* a live target (web exploitation,
pwn/binary exploitation against a running service) are not possible in this
model. Those would need the per-challenge container approach, which is noted as
future work.

---

## 4. Secrets handling — why flags live outside version control

There are two distinct classes of secret in this project, handled separately
because they have different consumers and lifecycles.

**Infrastructure secrets** (database passwords, CTFd's Flask `SECRET_KEY`) live
in a gitignored `.env` file at the repo root. The compose file references them
with `${VARIABLE}` substitution. The reference CTFd compose file ships these
hardcoded as `ctfd`/`ctfd`; that was replaced with generated 32-byte random
values so no real credential is ever committed.

**Challenge flags** live in a separate gitignored `challenges/flags.env`. Each
challenge's `build.sh` reads its flag from this file and bakes it into the
generated challenge artifact.

The critical rule: **no flag ever enters version control** — not as plaintext,
and not baked inside a committed pcap, archive, or log. The `dist/` folders that
hold the generated (flag-bearing) files are gitignored too. What *is* committed
is the *generator*: anyone cloning the repo gets the build scripts and can
regenerate every challenge with their own flags, but gets zero answers.

This was verified at each commit by inspecting `git status` before staging, to
confirm `flags.env` and `dist/` never appeared in the tracked set.

---

## 5. Volume persistence vs. data loss

CTFd persists three things to host-mounted volumes under `.data/`:

- `.data/mysql` — the MariaDB database (users, challenges, submissions)
- `.data/CTFd/uploads` — uploaded challenge files
- `.data/redis` — cache

This matters directly to this project: **the first version of this lab was lost
because its files were not under version control or backed up.** The rebuild
treats that as a lesson:

- All *configuration and source* (compose file, build scripts, docs) is under
  git and pushed to GitHub — it cannot be lost to a VM failure.
- All *generated state* (the database, uploads) lives in Docker volumes on the
  VM. This is deliberately **not** in git (it contains flags and user data),
  which means it is **not** protected by the same mechanism.

The honest consequence: if the VM is destroyed, the running CTFd state (accounts,
solves) is gone, but the entire platform can be **rebuilt from the repo** —
clone, regenerate challenges, `docker compose up`, reconfigure. The *durable*
asset is the repository, not the VM. For a production deployment, the volumes
would need a real backup strategy (scheduled `mysqldump`, off-host storage).

A related failure mode worth noting: `docker compose down` alone preserves
volumes; `docker compose down -v` **deletes** them. During the rebuild the data
directory was deliberately wiped once to reset a half-finished setup — a useful
reminder that volume lifecycle is a manual responsibility, not an automatic one.

---

## 6. What would change before exposing this to a real network

The current deployment is a lab: HTTP on a private VMware NAT network, reachable
only from the host. Before putting it on a real / hostile network, the following
would be required:

- **TLS / HTTPS.** Add a reverse proxy (nginx or Caddy) terminating TLS. The
  CTFd reference compose file includes an nginx service; it was removed here to
  cut scope, and `REVERSE_PROXY` was set to `false` accordingly. Re-adding it is
  the first production step.
- **Firewall segmentation.** Place the host behind pfSense with VLAN
  segmentation, isolating the platform, participants, and any admin network —
  mirroring the segmented-CTF-infrastructure approach rather than a single flat
  VM.
- **Email verification.** Currently disabled because no SMTP server is
  configured. A real deployment would configure mail and require verification to
  prevent throwaway-account abuse.
- **Rate-limiting and hardening review.** CTFd has built-in submission
  rate-limiting; on a public deployment its settings, plus reverse-proxy-level
  rate limits, would be tuned against brute-forcing flags.
- **Backups.** A scheduled database dump to off-host storage, so a VM failure
  does not lose live event state (the v1 lesson, applied).
- **Bind to a specific interface.** CTFd is exposed on `0.0.0.0:8000` for lab
  convenience; production would bind a specific interface behind the proxy.

---

## Summary

The design optimizes for **reproducibility, minimal attack surface, and clean
separation of secrets from code**, accepting deliberate scope cuts (no live
challenge containers, no reverse proxy, no email) that are documented here
rather than hidden. Every cut is a stated trade-off with a known upgrade path,
which is the point of this document.
