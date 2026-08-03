# Solution — Log Analysis: Who Got In

**Flag:** the attacker's IP, stored in `challenges/flags.env` as `FLAG_LOG`
(not committed). Regenerating the challenge produces a new random IP and
updates FLAG_LOG automatically.

## What the log contains

A synthetic auth.log with:
- Legitimate logins from the admin (rafik) from 10.10.10.5
- A burst of ~14 "Failed password" entries from a single attacker IP,
  cycling through common usernames (root, admin, oracle, ...)
- One "Accepted password for admin" from that same attacker IP — the breach
- Normal activity afterwards, so the compromise line is not simply the last
  line of the file

## Intended solve path

1. Count failed logins grouped by source IP:
```bash
   grep "Failed password" auth.log \
     | grep -oE "from [0-9.]+" | sort | uniq -c | sort -rn
```
   One IP dominates with ~14 failures. That is the attacker.

2. Confirm the breach — did that IP ever succeed?
```bash
   grep "Accepted password" auth.log
```
   The attacker IP appears on an "Accepted password for admin" line.

3. The flag is that IP: `CSI{<attacker_ip>}`.

## Concepts taught

- Reading Linux SSH authentication logs (auth.log)
- Recognizing a brute-force pattern: many failures, one source, short window
- Correlating a failed-attempt source with a later successful login to
  identify a compromise
- Command-line log triage with grep, sort, uniq — the core of first-pass
  incident analysis
