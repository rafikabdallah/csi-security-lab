#!/usr/bin/env bash
# Generates the packet-analysis pcap from the flag in flags.env.
# Forges a plaintext HTTP POST containing the flag, plus decoy traffic.
# Run from repo root:  bash challenges/03-packet-analysis/build.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAGS_FILE="$SCRIPT_DIR/../flags.env"
DIST="$SCRIPT_DIR/dist"
mkdir -p "$DIST"

# Export the flag so the Python block can read it from the environment
set -a
source "$FLAGS_FILE"
set +a
: "${FLAG_PCAP:?FLAG_PCAP not set in flags.env}"

OUT="$DIST/capture.pcap" python3 << 'PY'
import os
from scapy.all import Ether, IP, TCP, Raw, wrpcap

flag = os.environ["FLAG_PCAP"]
out  = os.environ["OUT"]

client = "10.10.10.5"
server = "10.10.10.80"
sport, dport = 49152, 80

def seg(src, dst, sp, dp, flags, seq, ack, payload=b""):
    p = Ether()/IP(src=src, dst=dst)/TCP(sport=sp, dport=dp, flags=flags,
                                         seq=seq, ack=ack)
    if payload:
        p = p/Raw(load=payload)
    return p

pkts = []

# --- Decoy: an unrelated DNS-ish plaintext chatter before the real session ---
pkts.append(seg(client, server, 40000, 80, "PA", 1, 1,
                b"GET /index.html HTTP/1.1\r\nHost: intranet.csi.local\r\n\r\n"))
pkts.append(seg(server, client, 80, 40000, "PA", 1, 55,
                b"HTTP/1.1 200 OK\r\nContent-Length: 13\r\n\r\nHello, world!"))

# --- Real session: TCP handshake ---
pkts.append(seg(client, server, sport, dport, "S", 1000, 0))
pkts.append(seg(server, client, dport, sport, "SA", 5000, 1001))
pkts.append(seg(client, server, sport, dport, "A", 1001, 5001))

# --- The HTTP POST carrying the flag in the body ---
body = f"username=admin&password={flag}"
req = (
    "POST /login HTTP/1.1\r\n"
    "Host: intranet.csi.local\r\n"
    "Content-Type: application/x-www-form-urlencoded\r\n"
    f"Content-Length: {len(body)}\r\n"
    "\r\n"
    f"{body}"
)
pkts.append(seg(client, server, sport, dport, "PA", 1001, 5001,
                req.encode()))

# --- Server response ---
resp = "HTTP/1.1 200 OK\r\nContent-Length: 22\r\n\r\nLogin successful. Welcome!"
pkts.append(seg(server, client, dport, sport, "PA", 5001,
                1001 + len(req), resp.encode()))

# --- Graceful close ---
pkts.append(seg(client, server, sport, dport, "FA",
                1001 + len(req), 5001 + len(resp)))
pkts.append(seg(server, client, dport, sport, "FA",
                5001 + len(resp), 1002 + len(req)))

wrpcap(out, pkts)
print(f"Wrote {len(pkts)} packets to {out}")
PY

echo "Built: $DIST/capture.pcap"
