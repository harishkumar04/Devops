journalctl is your primary tool for reading logs managed by systemd-journald. Unlike old-school log files in /var/log, the journal stores logs in a structured binary format with rich metadata — unit names, PIDs, UIDs, priorities, and timestamps — all queryable.
  
---

# How the Journal Works

Systemd captures stdout/stderr of every service it manages, plus kernel messages, and stores them in binary journal files under `/run/log/journal/` (volatile) or `/var/log/journal/` (persistent).

```shell
# Check if your journal is persistent
ls /var/log/journal/

# If empty, make it persistent:
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```
---

# The Problem It Solves

Before systemd, every service wrote logs wherever it wanted:

```python
   nginx    → /var/log/nginx/access.log, /var/log/nginx/error.log
   sshd     → /var/log/auth.log
   kernel   → /var/log/kern.log
   cron     → /var/log/cron.log
   your app → /var/log/myapp/app.log (if you configured it)
             → stdout (lost forever if not redirected)
             → /dev/null (if you forgot)
```

**Problem**: When something breaks, you're hunting across 20 different files, different formats, different timestamps, no correlation.
   
---

# What systemd-journald Does

There's a daemon called systemd-journald running on every systemd Linux system. It acts as a central log collector.

```text
   ┌─────────────────────────────────────────────-┐
   │           systemd-journald daemon            │
   │                                              │
   │  Collects from:                              │
   │  • Every service's stdout + stderr           │
   │  • Kernel (dmesg)                            │
   │  • /dev/log (syslog socket)                  │
   │  • systemd itself (service start/stop/fail)  │
   │                                              │
   │  Stores in: /var/log/journal/                │
   └─────────────────────────────────────────────-┘
              ↑
       journalctl reads this
```

When you run systemctl start nginx, systemd:

1. Starts nginx
2. Automatically captures nginx's stdout and stderr
3. Writes it to the journal with metadata: timestamp, unit name, PID, UID, priority, hostname

Your app doesn't need to configure any log file. Just print to stdout — journald catches it.

---

# Basic commands

```shell
journalctl                    # all logs, oldest first, paged
journalctl -r                 # reverse — newest first (most used in prod)
journalctl -n 50              # last 50 lines
journalctl -n 50 -r           # last 50 lines, newest first
journalctl --no-pager         # don't paginate (pipe-friendly)
journalctl -o short           # default format
journalctl -o json-pretty     # structured JSON output
journalctl -o cat             # message text only, no metadata
```
Production tip: `Always use --no-pager` in scripts so it doesn't hang waiting for user input.

---

# Filtering by Unit (Service)

This is the most common use — checking a specific service.

```shell
journalctl -u nginx                      # all logs for nginx
journalctl -u nginx -n 100               # last 100 lines
journalctl -u nginx -r -n 50             # last 50, newest first
journalctl -u nginx --no-pager           # script-safe, no pagination
journalctl -u nginx -u postgresql        # multiple units at once
journalctl -u "ssh*"                     # glob — matches sshd, ssh, etc.
```

Multiple units are OR'd — you get logs from any of the matched units.

---

# Filtering by Time

```shell
# Relative time
journalctl --since "1 hour ago"
journalctl --since "2 hours ago" --until "1 hour ago"
journalctl --since "yesterday"
journalctl --since "today"

# Absolute time (ISO 8601)
journalctl --since "2026-06-16 09:00:00"
journalctl --since "2026-06-16 08:00:00" --until "2026-06-16 10:00:00"

# Combine with unit
journalctl -u nginx --since "1 hour ago" --no-pager
```

Production use case: incident investigation window — you know the outage started at 14:32, so:

```bash
journalctl --since "2026-06-16 14:30:00" --until "2026-06-16 14:45:00" --no-pager
```
---

# Boot Logs

Each system boot gets an ID in the journal. Very useful for post-crash analysis.

```shell
journalctl --list-boots          # list all boot sessions with IDs and times
journalctl -b                    # current boot only
journalctl -b -1                 # previous boot (crashed/rebooted machine)
journalctl -b -2                 # two boots ago
journalctl -b 0                  # same as -b (current)

# Check previous boot for a specific service (crash analysis)
journalctl -b -1 -u nginx --no-pager

# Kernel messages from current boot
journalctl -b -k
```
Why this matters in production: If a server rebooted unexpectedly, journalctl -b -1 shows you everything from the session that ended — including the last messages before the crash.

---

# Filtering by Priority (Log Level)

```bash
journalctl -p err               # errors and above (err, crit, alert, emerg)
journalctl -p warning           # warnings and above
journalctl -p debug             # everything including debug

# Priority levels (0=emerg to 7=debug):
# 0=emerg  1=alert  2=crit  3=err  4=warning  5=notice  6=info  7=debug

# Range: from warning down to err
journalctl -p warning..err

# Combine: errors from nginx in the last hour
journalctl -u nginx -p err --since "1 hour ago" --no-pager
```
---

# Live Log Tailing

```shell
journalctl -f                    # follow all logs (like tail -f)
journalctl -f -u nginx           # follow only nginx logs
journalctl -f -u nginx -p err    # follow only nginx errors live
journalctl -f -u nginx -u mysql  # follow multiple services live
```

Production use case: Deploy a service update, then run journalctl -f -u myapp in another terminal to watch logs in real time during rollout.

---

# Filtering by Field (Advanced)

The journal stores structured fields. You can filter on any of them.

```bash
journalctl _SYSTEMD_UNIT=nginx.service    # same as -u nginx but explicit field
journalctl _PID=1234                      # logs from a specific PID
journalctl _UID=1000                      # logs from a specific user ID
journalctl _COMM=python3                  # logs from processes named python3
journalctl _EXE=/usr/bin/python3          # logs from a specific binary path

# Multiple fields = AND
journalctl _COMM=sshd _PID=5678
```

To see what fields are available:

```shell
journalctl -o json -n 1 | python3 -m json.tool   # inspect all fields on one entry
```

---

# Disk Usage & Maintenance

```shell
journalctl --disk-usage              # how much space the journal is using
journalctl --verify                  # verify journal file integrity

# Vacuum (clean up old entries)
sudo journalctl --vacuum-time=7d     # keep only last 7 days
sudo journalctl --vacuum-size=500M   # keep only 500MB of logs
sudo journalctl --vacuum-files=5     # keep only 5 journal files
```

Production practice: Set limits in `/etc/systemd/journald.conf` so the journal doesn't eat your disk:

```bash
  [Journal]
  SystemMaxUse=500M
  SystemKeepFree=1G
  MaxRetentionSec=2weeks
```
After editing: `sudo systemctl restart systemd-journald`

---

# One-Liners Worth Memorizing

```shell
# Is anything broken right now?
journalctl -p err -b --no-pager | tail -20

# What failed in the last 10 minutes?
journalctl -p err --since "-10min" --no-pager

# Full error picture for one service since restart
journalctl -u myapp -b --no-pager -p warning

# How noisy is my journal?
journalctl --disk-usage

# Who logged in via SSH today?
journalctl _COMM=sshd --since "today" --no-pager | grep "Accepted"

journalctl -u SERVICE -n 100 --no-pager         # last 100 lines for a service
journalctl -u SERVICE -f                         # live tail a service
journalctl -u SERVICE --since "1 hour ago"       # last hour of logs
journalctl -b -1 -u SERVICE                      # previous boot logs
journalctl -p err --since "today" --no-pager     # all errors today
journalctl --list-boots                          # all boot sessions
journalctl --disk-usage                          # journal disk usage
sudo journalctl --vacuum-time=7d                 # clean logs older than 7 days
 ```
 ---

# The 4 Main Ways to Identify a Service's Logs

## 1. By systemd unit name (-u) — most common

```shell
   journalctl -u nginx          # nginx.service
   journalctl -u myapp          # myapp.service
   journalctl -u postgresql     # postgres
```

This works for anything managed by systemctl. If you did systemctl start nginx, use -u nginx.

## 2. By process name (_COMM) — when not a systemd service

```shell
journalctl _COMM=nginx       # process binary named "nginx"
journalctl _COMM=python3     # any python3 process
journalctl _COMM=myapp       # your app's binary name
```
Use this when the process wasn't started by systemctl directly.

## 3. By executable path (_EXE)

```shell
journalctl _EXE=/usr/sbin/nginx
journalctl _EXE=/home/harish/myapp/server
```
Useful when two different apps use the same binary name (e.g., two python scripts).

## 4. By PID (_PID) — when you know the exact process

```shell
pgrep nginx          # get the PID first
journalctl _PID=1234
```
---

# SSH Commands example

```shell
# 1. See last 20 lines of ssh logs
journalctl -u ssh -n 20 --no-pager

# 2. See ssh logs from today only
journalctl -u ssh --since "today" --no-pager

# 3. Live tail ssh (open a new terminal and SSH into your VM to trigger a log entry, then watch it appear)
journalctl -u ssh -f
   
# 4. Filter by priority — only errors
journalctl -u ssh -p err --no-pager

# 5. Check previous boot logs
journalctl --list-boots
journalctl -b -1 -n 30 --no-pager

# 6. See all errors across ALL services since today
journalctl -p err --since "today" --no-pager

# logs between two exact times
journalctl --since "04:45:00" --until "04:47:00" --no-pager
```

---

# Practice Script 1:  Failed Service Analyzer

```shell
   #!/usr/bin/env bash
   set -euo pipefail

   LINES="${1:-20}"

   failed=$(systemctl list-units --state=failed --no-legend --no-pager | awk '{print $1}')

   if [[ -z "$failed" ]]; then
       echo "No failed services."
       exit 0
   fi

   echo "=== Failed Services ==="
   echo "$failed"
   echo ""

   while IFS= read -r unit; do
       echo "--- $unit ---"
       journalctl -u "$unit" -n "$LINES" --no-pager 2>/dev/null || echo "(no logs)"
       echo ""
   done <<< "$failed"
```

```shell
chmod +x failed_service_analyzer.sh
./failed_service_analyzer.sh        # last 20 lines per failed service
./failed_service_analyzer.sh 50     # last 50 lines
```
---

# Practice Script 2: SSH Login Tracker

```shell
   #!/usr/bin/env bash
   set -euo pipefail

   SINCE="${1:-today}"

   echo "=== SSH Report (since: $SINCE) ==="

   echo ""
   echo "--- Successful Logins ---"
   journalctl _COMM=sshd --since "$SINCE" --no-pager -o cat 2>/dev/null \
       | grep "Accepted" \
       | awk '{print "user="$9, "from="$11}' \
       | sort | uniq -c | sort -rn

   echo ""
   echo "--- Failed Attempts ---"
   journalctl _COMM=sshd --since "$SINCE" --no-pager -o cat 2>/dev/null \
       | grep "Failed password" \
       | awk '{print "user="$9, "from="$11}' \
       | sort | uniq -c | sort -rn

   echo ""
   echo "--- Top Attacker IPs ---"
   journalctl _COMM=sshd --since "$SINCE" --no-pager -o cat 2>/dev/null \
       | grep -E "Failed|Invalid" \
       | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
       | sort | uniq -c | sort -rn | head -10
```
```shell
   chmod +x ssh_login_tracker.sh
   ./ssh_login_tracker.sh              # since today
   ./ssh_login_tracker.sh "1 hour ago"
```
