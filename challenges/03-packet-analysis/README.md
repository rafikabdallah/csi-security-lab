# Packet Analysis — Clear Text

**Category:** Packet Analysis
**Difficulty:** Easy / Medium
**Points:** 100

## Description

A user logged into an internal web application over plain HTTP — no HTTPS,
no encryption. We captured the network traffic. Somewhere in this packet
capture, a secret was sent across the wire in the clear.

Open the capture in Wireshark and recover the flag.

## Hints

1. HTTP is not encrypted. Try Wireshark's "Follow > HTTP Stream" (or
   "Follow > TCP Stream") on the interesting packets. (Cost: 10 pts)
2. Login forms send data with a POST request. Look for the request that
   submits a username and password. (Cost: 15 pts)

## Files

- `capture.pcap`

## Flag format

`CSI{...}`
