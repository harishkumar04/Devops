# What is systemd?

When Linux boots, something has to start all the services — SSH, networking, databases, web servers, etc. That "something" is `systemd`, and it's the init system on almost every modern Linux distro (Ubuntu, Debian, CentOS, RHEL, Arch).

`systemctl` is the command you use to talk to systemd.

```
You → systemctl → systemd → service (nginx, sshd, etc.)
```

systemd is **PID 1** — the first process the kernel starts. Everything else is a child of systemd.

```
Boot → systemd (PID 1) → reads unit files → starts services in dependency order
```

---

# Core Concepts

## Units

Everything in systemd is a **unit**. A service is just one type of unit.

| Unit Type | Extension  | What it is                      |
| --------- | ---------- | ------------------------------- |
| Service   | `.service` | A daemon/process (nginx, sshd)  |
| Timer     | `.timer`   | Like cron jobs                  |
| Socket    | `.socket`  | Network socket activation       |
| Target    | `.target`  | Group of units (like runlevels) |
| Mount     | `.mount`   | Filesystem mount points         |

## Service States

| State | Meaning |
|-------|---------|
| `active (running)` | Process is up and running |
| `active (exited)` | Ran once and exited cleanly (e.g. a oneshot script) |
| `inactive (dead)` | Stopped |
| `failed` | Crashed or exited with error |
| `activating` | Starting up |
| `deactivating` | Shutting down |

## Where Unit Files Live

| Location | Purpose |
|----------|---------|
| `/lib/systemd/system/` | Package-installed originals — **never edit these** |
| `/etc/systemd/system/` | Your custom services and overrides — edit here |
| `/etc/systemd/system/<svc>.d/override.conf` | Partial overrides — safest approach |
| `/run/systemd/system/` | Runtime units (temporary, lost on reboot) |

> **Rule:** Never edit `/lib/systemd/system/`. Since `apt upgrade nginx` will overwrite your changes. Always use `/etc/systemd/system/` or overrides.

---

# Essential Commands

## Check Status

```bash
systemctl status nginx
systemctl status sshd
systemctl status nginx.service   # same thing, .service is optional
```

**Reading the output:**
```
● nginx.service - A high performance web server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2026-06-26 09:00:00 IST; 5h ago
       Docs: man:nginx(8)
   Main PID: 1234 (nginx)
      Tasks: 2 (limit: 4915)
     Memory: 3.5M
        CPU: 210ms
     CGroup: /system.slice/nginx.service
             ├─1234 nginx: master process
             └─1235 nginx: worker process
```

- **Loaded** → config file path + whether it's enabled on boot
- **Active** → current state + how long it's been running
- **Main PID** → the process ID
- **CGroup** → all processes belonging to this service
- **Bottom lines** → recent logs (last ~10 lines from journald)

---

## Start / Stop / Restart / Reload

```bash
sudo systemctl start nginx       # start right now
sudo systemctl stop nginx        # stop right now
sudo systemctl restart nginx     # stop + start (brief downtime)
sudo systemctl reload nginx      # reload config without killing process (zero downtime)
sudo systemctl reload-or-restart nginx   # reload if supported, else restart
```

> **Production rule:** always prefer `reload` over `restart` for services that support it (nginx, apache, haproxy). Reload = zero downtime. Restart = brief gap.

Check if a service supports reload:
```bash
systemctl cat nginx | grep ExecReload
```

---

## Enable / Disable (Boot Persistence)

```bash
sudo systemctl enable nginx          # start on boot (doesn't start now)
sudo systemctl disable nginx         # don't start on boot (doesn't stop now)
sudo systemctl enable --now nginx    # enable + start immediately ← use this in production
sudo systemctl disable --now nginx   # disable + stop immediately
systemctl is-enabled nginx           # prints: enabled / disabled / static
```

> **Important:** `start` = start right now, won't survive reboot. `enable` = boot only, not now. `enable --now` = both. Always use `enable --now` when deploying a new service.

---

## Check If Running (Script-Friendly)

```bash
systemctl is-active nginx        # prints "active" or "inactive", exit code 0 or 1
systemctl is-enabled nginx       # prints "enabled" or "disabled"
systemctl is-failed nginx        # prints "failed" if in failed state
```

Use `--quiet` in scripts — suppresses text output, only sets exit code:
```bash
if systemctl is-active --quiet nginx; then
    echo "nginx is running"
else
    echo "nginx is down"
fi

# One-liner: restart if not running
systemctl is-active --quiet nginx || sudo systemctl start nginx

# Check exit code manually
systemctl is-active --quiet nginx
echo $?    # 0 = active, non-zero = not active
```

---

## List Services

```bash
systemctl list-units --type=service                        # all loaded services
systemctl list-units --type=service --state=running        # only running
systemctl list-units --type=service --state=failed         # only failed
systemctl list-units --type=service --all                  # all including inactive
systemctl list-unit-files --type=service                   # all installed + enabled/disabled status
systemctl --failed                                         # quick view of all failed units
```

> When debugging a broken system, `systemctl --failed` is your first command.

---

# Viewing Unit Files

## See the Effective Config

```bash
systemctl cat nginx
```

This shows the actual file(s) being used, including any overrides, with file paths at the top:
```
# /lib/systemd/system/nginx.service
[Unit]
Description=A high performance web server
...
# /etc/systemd/system/nginx.service.d/override.conf
[Service]
Restart=always
```

## Find the File Path

```bash
systemctl show nginx -p FragmentPath
# Output: FragmentPath=/lib/systemd/system/nginx.service
```

## Inspect All Properties

```bash
systemctl show nginx                      # every property systemd knows
systemctl show nginx -p MainPID           # just the PID
systemctl show nginx -p Restart           # restart policy
systemctl show nginx -p ExecStart         # what command starts it
systemctl show nginx -p Environment       # environment variables
systemctl show nginx -p User              # which user it runs as
```

## See Dependencies

```bash
systemctl list-dependencies nginx         # what nginx depends on
systemctl list-dependencies nginx --reverse  # what depends on nginx
```

---

# Editing Unit Files

## Option A — `systemctl edit` (Recommended)

```bash
sudo systemctl edit nginx
```

Creates a **drop-in override** at `/etc/systemd/system/nginx.service.d/override.conf`.  
You only write the sections/lines you want to change. The original file stays intact.

Example — change restart policy:
```ini
[Service]
Restart=always
RestartSec=10
```

- Safe: package upgrades won't overwrite your override
- `daemon-reload` runs automatically after `systemctl edit`

## Option B — `systemctl edit --full` (Full Copy)

```bash
sudo systemctl edit --full nginx
```

Copies the entire unit file to `/etc/systemd/system/nginx.service` and opens it.  
Use when you need major structural changes.

## Option C — Manual Edit

```bash
# Edit an override manually
sudo vim /etc/systemd/system/nginx.service.d/override.conf

# Or create a custom service from scratch
sudo vim /etc/systemd/system/myapp.service

# ALWAYS reload after manual edits
sudo systemctl daemon-reload
```

## Applying Changes

```bash
# Step 1 — mandatory after any file edit
sudo systemctl daemon-reload

# Step 2 — apply to running service
sudo systemctl restart nginx      # full restart
# OR
sudo systemctl reload nginx       # graceful reload (prefer this)

# Verify the change applied
systemctl show nginx -p Restart
systemctl cat nginx
systemctl status nginx
```

## Check What Overrides Exist

```bash
ls /etc/systemd/system/                          # list all overrides/custom services
ls /etc/systemd/system/nginx.service.d/          # overrides for nginx specifically
```

## Revert to Original (Remove Your Overrides)

```bash
sudo systemctl revert nginx
# Removes your overrides, restores package default
```

---

# Unit File Anatomy

```ini
[Unit]
Description=My App                  # human-readable name
After=network.target                # start after networking is up
Wants=network.target                # soft dependency (won't fail if missing)
Requires=postgresql.service         # hard dependency (fails if missing)

[Service]
Type=simple                         # how the process behaves at start
User=appuser                        # run as this user — never root
WorkingDirectory=/opt/myapp         # working directory
ExecStart=/opt/myapp/start.sh       # command to start the service
ExecStartPre=/opt/myapp/precheck.sh # run before starting
ExecStop=/opt/myapp/stop.sh         # custom stop command
Restart=on-failure                  # auto-restart if it crashes
RestartSec=5                        # wait 5s before restarting
StandardOutput=journal              # send stdout to journald
StandardError=journal               # send stderr to journald
Environment=NODE_ENV=production     # set environment variables
Environment=PORT=3000
LimitNOFILE=65536                   # max open file descriptors

[Install]
WantedBy=multi-user.target          # enable for normal multi-user boot
```

## Service Types

| Type | Meaning |
|------|---------|
| `simple` | ExecStart is the main process, runs in foreground (most common) |
| `forking` | Process forks to background (traditional daemons: nginx, apache) |
| `oneshot` | Runs once and exits — systemd waits for it to finish (good for scripts) |
| `notify` | Like simple, but process sends a ready signal (advanced) |

## Restart Policies

```ini
Restart=always          # restart no matter what (crash, clean exit, signal)
Restart=on-failure      # restart only on non-zero exit code (recommended)
Restart=on-abnormal     # restart on signal/timeout, not clean exit
Restart=no              # never restart
```

## Crash Loop Protection

Prevent a broken service from restarting infinitely:
```ini
Restart=on-failure
RestartSec=5
StartLimitIntervalSec=60    # in any 60 second window...
StartLimitBurst=3           # ...allow max 3 restarts before giving up
```

After hitting the limit, the service enters `failed` state. Reset it manually:
```bash
sudo systemctl reset-failed myapp
sudo systemctl start myapp
```

---

# Logs — journalctl

`systemctl status` shows only the last few lines. Use `journalctl` for full logs:

```bash
journalctl -u nginx                              # all logs for nginx
journalctl -u nginx -f                           # follow/tail live logs
journalctl -u nginx -n 50                        # last 50 lines
journalctl -u nginx -p err                       # only error-level logs
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx --since "2026-08-24 10:00" --until "2026-08-24 11:00"
journalctl -u nginx --no-pager                   # don't paginate (good for scripts)
```

When a service fails, always run both:
```bash
systemctl status nginx
journalctl -u nginx -n 100 --no-pager
```

---

# Checking Processes

## systemd Level

```bash
systemctl list-units --type=service --state=running    # services view
systemctl --failed                                      # all failed units
```

## OS Level — ps

```bash
ps aux                          # all processes, all users
ps aux | grep nginx             # filter for specific process
ps aux --sort=-%cpu             # sort by CPU (highest first)
ps aux --sort=-%mem             # sort by memory (highest first)
ps aux | head -20               # top 20 processes
```

Output columns:
```
USER    PID  %CPU  %MEM    VSZ   RSS TTY  STAT  START   TIME  COMMAND
root   1235   0.0   0.1  55680  3456  ?    Ss   10:00   0:00  nginx: master
```
- **PID** — process ID
- **%CPU / %MEM** — resource usage
- **RSS** — actual RAM used (resident set size)
- **STAT** — S=sleeping, R=running, Z=zombie, D=disk wait

## Find PID of a Process

```bash
pidof nginx                     # returns PID(s) of nginx
pgrep nginx                     # same, more flexible
pgrep -l nginx                  # PID + process name
pgrep -a nginx                  # PID + full command line
pgrep -u root                   # all processes running as root
```

## Get PID Directly from systemd

```bash
systemctl show nginx -p MainPID
# Output: MainPID=1235

# Inspect that PID in /proc
cat /proc/1235/status           # process state, memory, threads
cat /proc/1235/cmdline          # exact command that started it
ls -la /proc/1235/fd/           # open file descriptors
```

## Live Process Monitors

```bash
top                             # live view, updates every 3 seconds
htop                            # better version (colored, mouse support)
```

Inside `top`:
- `P` — sort by CPU
- `M` — sort by memory
- `k` — kill a process (type PID)
- `q` — quit

## Process Tree

```bash
pstree                          # full process tree
pstree -p                       # with PIDs
pstree -u                       # with usernames
pstree nginx                    # tree rooted at nginx process
```

---

# Masking / Unmasking

Masking is stronger than disabling. A disabled service can still be started manually. A masked service **cannot be started at all**.

```bash
sudo systemctl mask nginx       # completely block (even manual start)
sudo systemctl unmask nginx     # remove the block
```

Use case: prevent legacy/dangerous services (telnet, rsh) from ever running.

---

# Timers (systemd Alternative to Cron)

More robust than cron — logs to journald, handles missed runs, integrates with dependencies.

You need two files: a `.service` (what to run) and a `.timer` (when to run it).

`/etc/systemd/system/cleanup.service`:
```ini
[Unit]
Description=Daily cleanup job

[Service]
Type=oneshot
ExecStart=/opt/scripts/cleanup.sh
```

`/etc/systemd/system/cleanup.timer`:
```ini
[Unit]
Description=Run cleanup daily

[Timer]
OnCalendar=daily              # every day at midnight
Persistent=true               # run missed jobs on next boot

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now cleanup.timer
systemctl list-timers                      # see all timers + next run time
```

---

# Production Patterns (Scripts)

## Check if service is active
```bash
if systemctl is-active --quiet nginx; then
    echo "nginx is running"
fi
```

## Restart if not running
```bash
systemctl is-active --quiet nginx || sudo systemctl restart nginx
```

## Check and restart with logging
```bash
#!/usr/bin/env bash
set -euo pipefail

SERVICE="nginx"

if ! systemctl is-active --quiet "$SERVICE"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $SERVICE is down — restarting" >&2
    systemctl restart "$SERVICE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $SERVICE restarted successfully"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $SERVICE is running"
fi
```

## Check multiple services
```bash
#!/usr/bin/env bash
set -euo pipefail

SERVICES=("nginx" "mysql" "redis")

for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "✅ $service — running"
    else
        echo "❌ $service — DOWN"
    fi
done
```

## Wait for a service to come up
```bash
#!/usr/bin/env bash

SERVICE="postgresql"
TIMEOUT=30
ELAPSED=0

until systemctl is-active --quiet "$SERVICE" || [[ $ELAPSED -ge $TIMEOUT ]]; do
    echo "Waiting for $SERVICE... (${ELAPSED}s)"
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

if systemctl is-active --quiet "$SERVICE"; then
    echo "$SERVICE is up"
else
    echo "ERROR: $SERVICE did not start within ${TIMEOUT}s" >&2
    exit 1
fi
```

## Graceful reload with config test fallback
```bash
#!/usr/bin/env bash
set -euo pipefail

# Test config before reloading — never reload a broken config
nginx -t 2>/dev/null \
    && systemctl reload nginx \
    || { echo "Config test failed — not reloading" >&2; exit 1; }
```

## Full edit → apply → verify workflow
```bash
# 1. View current state
systemctl status nginx
systemctl cat nginx
systemctl show nginx -p Restart

# 2. Edit (safest method)
sudo systemctl edit nginx

# 3. Reload systemd
sudo systemctl daemon-reload

# 4. Apply to running service
sudo systemctl reload-or-restart nginx

# 5. Verify
systemctl show nginx -p Restart
systemctl status nginx
ps aux | grep nginx
```

---

# Quick Reference

```bash
# Status & Info
systemctl status <svc>
systemctl is-active --quiet <svc>    # exit code: 0=active, non-zero=not
systemctl is-enabled <svc>
systemctl --failed                   # all failed units (first debug command)

# Control
systemctl start/stop/restart/reload <svc>
systemctl enable --now <svc>         # enable + start (use this in prod)
systemctl disable --now <svc>        # disable + stop
systemctl mask/unmask <svc>

# View Unit Files
systemctl cat <svc>                  # effective config (original + overrides)
systemctl show <svc> -p <Property>   # specific property

# Edit Unit Files
systemctl edit <svc>                 # override (safest)
systemctl edit --full <svc>          # full copy edit
systemctl daemon-reload              # MANDATORY after any manual edit
systemctl revert <svc>               # undo all overrides

# Logs
journalctl -u <svc> -f               # follow live logs
journalctl -u <svc> -n 100 --no-pager

# Processes
ps aux --sort=-%cpu                  # all processes sorted by CPU
pgrep -a <name>                      # PID + command
systemctl show <svc> -p MainPID      # get PID from systemd

# Recovery
systemctl reset-failed <svc>         # clear failed state before manual start
systemctl list-timers                # see all timers + next run time
```

---

# Script 1 : Service Status Checker

Check if a given service is active or inactive. Takes a service name as an argument, validates it exists, prints a clear status message with timestamp, and exits with the appropriate exit code.

```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "The number of arguments entered is 0 enter the correct ones" >&2
    exit 1
fi

service="$1"

if ! systemctl list-units --type=service | grep -q "^${SERVICE}\.service"; then
   echo "[ERROR] The given service does not exist" >&2
   exit 1
fi

status=$(systemctl is-active "$service")
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

case "$status" in
   active)
       echo "[$timestamp] $service is RUNNING (active)"
       ;;
   inactive)
       echo "[$timestamp] $service is STOPPED (inactive)"
       ;;
   failed)
       echo "[$timestamp] $service has FAILED"
       ;;
   *)
       echo "[$timestamp] $service is in unknown state: $status"
       ;;
esac

if [[ "$STATUS" == "active" ]]; then
    exit 0
else
    exit 1
fi
```

---

# Script 2 : Service Restarter

Takes a service name as an argument, checks if it's currently running, and if not — restarts it with full logging (timestamp, what it found, what it did, whether it succeeded). If it's already running, just confirm and exit cleanly.

```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
   echo "Usuage: $0 <service_name>" >&2
   exit 1
fi

service="$1"
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
status="$(systemctl is-active "$service")"

if ! systemctl is-active "$service"; then
    echo "[$timestamp] $service is down — restarting" >&2
    systemctl restart "$SERVICE"
    echo "[$timestamp] $service restarted successfully"
else
    echo "[$timestamp] $service is running"
    exit 0
fi

if [[ "$status" == "active" ]]; then
    exit 0
else
    exit 1
fi
```

# Key Production Rules

1. **Never run services as root** — always set `User=` in the unit file
2. **`daemon-reload` is mandatory** after any manual unit file edit
3. **Use `enable --now`** when deploying — don't forget `--now`
4. **Prefer `reload` over `restart`** — avoid downtime on config changes
5. **Use `is-active --quiet` in scripts** — clean exit codes, no noise
6. **`systemctl --failed` first** when debugging a broken system
7. **Set `Restart=on-failure` + `StartLimitBurst`** — auto-recovery with crash loop protection
8. **`StandardOutput=journal`** — always log to journald so logs are queryable
9. **`reset-failed` before manually starting a failed service** — clears the failed state
10. **Use `systemctl edit`** not direct file edits — overrides survive package upgrades

    
