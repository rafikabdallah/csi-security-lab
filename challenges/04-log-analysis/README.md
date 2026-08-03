# Log Analysis — Who Got In

**Category:** Log Analysis
**Difficulty:** Medium
**Points:** 100

## Description

Our SSH server's authentication log looks noisier than usual. Someone spent
the early hours of the morning hammering the login prompt — and we're worried
one of those attempts actually worked.

Analyze the log, identify the attacker, and confirm the breach. The flag is
the attacker's IP address.

## Hints

1. A brute-force attack means many failed logins from a single source in a
   short window. Count failed attempts per IP address. (Cost: 10 pts)
2. Once you know the attacker's IP, check whether that same IP ever produced
   an "Accepted password" line. That's the moment they got in. (Cost: 15 pts)

## Files

- `auth.log`

## Flag format

`CSI{<attacker_ip>}` — for example, `CSI{203.0.113.45}`
