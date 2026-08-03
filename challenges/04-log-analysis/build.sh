#!/usr/bin/env bash
# Generates a synthetic auth.log containing an SSH brute-force attack.
# The flag is the attacker's IP: CSI{<ip>}. Both the log and the flag are
# derived from the same generated IP, and FLAG_LOG is written back to
# flags.env so CTFd's expected answer stays in sync.
# Run from repo root:  bash challenges/04-log-analysis/build.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAGS_FILE="$SCRIPT_DIR/../flags.env"
DIST="$SCRIPT_DIR/dist"
mkdir -p "$DIST"

ATTACKER_IP="ATTACKER_IP=$(( RANDOM % 200 + 20 ))" # placeholder, replaced below

OUT="$DIST/auth.log" FLAGS_FILE="$FLAGS_FILE" python3 << 'PY'
import os, random
from datetime import datetime, timedelta

out = os.environ["OUT"]
flags_file = os.environ["FLAGS_FILE"]

# --- Random attacker IP (avoids .0/.255, keeps it plausible) ---
attacker = f"{random.randint(11,223)}.{random.randint(0,255)}." \
           f"{random.randint(0,255)}.{random.randint(2,254)}"

host = "csi-server"
t = datetime(2026, 2, 14, 3, 11, 0)
lines = []

def stamp(dt):
    return dt.strftime("%b %e %H:%M:%S")

def add(dt, msg):
    lines.append(f"{stamp(dt)} {host} {msg}")

# --- Legit background activity before the attack ---
add(t, "sshd[812]: Accepted password for rafik from 10.10.10.5 port 51022 ssh2")
t += timedelta(minutes=7)
add(t, "sshd[840]: Accepted publickey for rafik from 10.10.10.5 port 51044 ssh2")
t += timedelta(minutes=23)

# --- Brute-force burst from the attacker ---
usernames = ["root","admin","test","oracle","postgres","ubuntu","git",
             "user","deploy","root","admin","root","www-data","root"]
port = 40000
for u in usernames:
    add(t, f"sshd[{random.randint(2000,2999)}]: Failed password for "
           f"{'invalid user ' if u in ('oracle','git','deploy') else ''}{u} "
           f"from {attacker} port {port} ssh2")
    t += timedelta(seconds=random.randint(1,3))
    port += random.randint(1,4)

# --- The successful compromise (same attacker IP) ---
add(t, f"sshd[3110]: Accepted password for admin from {attacker} "
       f"port {port} ssh2")
t += timedelta(seconds=2)
add(t, f"sshd[3110]: pam_unix(sshd:session): session opened for user "
       f"admin by (uid=0)")
t += timedelta(minutes=1)

# --- Normal activity afterwards, so the compromise isn't the last line ---
add(t, "sshd[3140]: Accepted publickey for rafik from 10.10.10.5 port 51099 ssh2")
t += timedelta(minutes=4)
add(t, "sshd[3140]: Received disconnect from 10.10.10.5 port 51099:11: disconnected by user")

with open(out, "w") as f:
    f.write("\n".join(lines) + "\n")

# --- Derive the flag and write it back into flags.env ---
flag = f"CSI{{{attacker}}}"
with open(flags_file) as f:
    content = f.read().splitlines()
new = []
found = False
for line in content:
    if line.startswith("FLAG_LOG="):
        new.append(f"FLAG_LOG={flag}")
        found = True
    else:
        new.append(line)
if not found:
    new.append(f"FLAG_LOG={flag}")
with open(flags_file, "w") as f:
    f.write("\n".join(new) + "\n")

print(f"Attacker IP: {attacker}")
print(f"Flag:        {flag}")
print(f"Wrote log:   {out}")
PY

echo "Built: $DIST/auth.log"
