# Solution — Packet Analysis: Clear Text

**Flag:** stored in `challenges/flags.env` as `FLAG_PCAP` (not committed).

## What the capture contains

A forged (Scapy-generated) plaintext HTTP session:
- A decoy GET request to /index.html (noise, no flag)
- A full TCP handshake (SYN, SYN-ACK, ACK)
- A POST /login request whose body carries the flag as the password field
- A 200 OK response and graceful FIN close

## Intended solve path (Wireshark)

1. Open capture.pcap in Wireshark.
2. Filter to HTTP: type `http` in the display filter, or look for the
   POST /login packet in the packet list.
3. Right-click that packet -> Follow -> HTTP Stream (or TCP Stream).
4. Read the reassembled conversation. The POST body shows:
   `username=admin&password=CSI{plaintext_http_is_not_private}`

## Alternative solve paths

- Command line: `strings capture.pcap | grep CSI`
  (strings extraction is a legitimate technique; both are valid.)
- `tshark -r capture.pcap -Y http.request.method==POST -T fields -e http.file_data`

## Build note / trade-off

The pcap is synthetically forged with Scapy rather than captured live.
This keeps it fully reproducible and lets the flag be injected from
flags.env. The trade-off: forged traffic is "cleaner" than a real capture
(no retransmissions, no timing jitter). For a beginner challenge this
reduces noise and is a net positive.

## Concepts taught

- HTTP is plaintext; anything sent over it is visible to anyone capturing.
- Wireshark "Follow Stream" to reassemble a TCP conversation.
- Reading HTTP requests/responses and identifying POST form data.
- Why HTTPS/TLS exists.
