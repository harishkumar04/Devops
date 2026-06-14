The Problem It Solves

   Before systemd, every service wrote logs wherever it wanted:

   nginx    → /var/log/nginx/access.log, /var/log/nginx/error.log
   sshd     → /var/log/auth.log
   kernel   → /var/log/kern.log
   cron     → /var/log/cron.log
   your app → /var/log/myapp/app.log (if you configured it)
             → stdout (lost forever if not redirected)
             → /dev/null (if you forgot)

   Problem: When something breaks, you're hunting across 20 different files, different formats, different timestamps, no correlation.
   
---

   What systemd-journald Does

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

# One-Liners Worth Memorizing

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
 
 ---
 
 # The 4 Main Ways to Identify a Service's Logs

   1. By systemd unit name (-u) — most common

   journalctl -u nginx          # nginx.service
   journalctl -u myapp          # myapp.service
   journalctl -u postgresql     # postgres

   This works for anything managed by systemctl. If you did systemctl start nginx, use -u nginx.

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   2. By process name (_COMM) — when not a systemd service

   journalctl _COMM=nginx       # process binary named "nginx"
   journalctl _COMM=python3     # any python3 process
   journalctl _COMM=myapp       # your app's binary name

   Use this when the process wasn't started by systemctl directly.

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   3. By executable path (_EXE)

   journalctl _EXE=/usr/sbin/nginx
   journalctl _EXE=/home/harish/myapp/server

   Useful when two different apps use the same binary name (e.g., two python scripts).

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   4. By PID (_PID) — when you know the exact process

   pgrep nginx          # get the PID first
   journalctl _PID=1234



# SSH Commands example

   1. See last 20 lines of ssh logs

   journalctl -u ssh -n 20 --no-pager

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   2. See ssh logs from today only

   journalctl -u ssh --since "today" --no-pager

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   3. Live tail ssh (open a new terminal and SSH into your VM to trigger a log entry, then watch it appear)

   journalctl -u ssh -f
   
   4. Filter by priority — only errors

   journalctl -u ssh -p err --no-pager

   5. Check previous boot logs

   journalctl --list-boots
   journalctl -b -1 -n 30 --no-pager

   6. See all errors across ALL services since today

   journalctl -p err --since "today" --no-pager

   # logs between two exact times
   journalctl --since "04:45:00" --until "04:47:00" --no-pager

   
   Script 1 — Failed Service Analyzer

   Save as failed_service_analyzer.sh:

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

   chmod +x failed_service_analyzer.sh
   ./failed_service_analyzer.sh        # last 20 lines per failed service
   ./failed_service_analyzer.sh 50     # last 50 lines

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   Script 2 — SSH Login Tracker

   Save as ssh_login_tracker.sh:

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

   chmod +x ssh_login_tracker.sh
   ./ssh_login_tracker.sh              # since today
   ./ssh_login_tracker.sh "1 hour ago"
