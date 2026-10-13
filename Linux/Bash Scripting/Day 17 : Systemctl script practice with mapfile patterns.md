# Script 1 — failed_service_detector.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

mapfile -t arr < <(systemctl list-units --state=failed --type=service --no-legend --plain | awk '{print $1}')

for svc in "${arr[@]}"; do
    echo "Found failed service: $svc"
done
```

# Script 2 — auto_recovery.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

MAX_RESTARTS=3
NEVER_RESTART=("database.service" "payment-gateway.service")

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

mapfile -t arr < <(systemctl list-units --state=failed --type=service --noint $1}')

if [[ ${#arr[@]} -eq 0 ]]; then
    echo "$(timestamp) No failed services found."
    exit 0
fi

for svc in "${arr[@]}"; do
    # 1. Never-restart list
    if [[ " ${NEVER_RESTART[@]} " == *" $svc "* ]]; then
        echo "$(timestamp) SKIP: $svc is on the never-auto-restart list. A
        continue
    fi

    # 2. Crash-loop cap
    countfile="/var/tmp/${svc}.restart_count"
    count=0
    [[ -f "$countfile" ]] && count=$(cat "$countfile")

    if [[ "$count" -ge "$MAX_RESTARTS" ]]; then
        echo "$(timestamp) ALERT: $svc has failed $count times. Needs a hu
        continue
    fi

    # 3. Restart
    echo "$(timestamp) Restarting $svc (attempt $((count + 1)))..."
    systemctl restart "$svc"

    # 4. Verify
    sleep 3
    if systemctl is-active --quiet "$svc"; then
        echo "$(timestamp) SUCCESS: $svc is back up."
        rm -f "$countfile"
    else
        count=$((count + 1))
        echo "$count" > "$countfile"
        echo "$(timestamp) FAILED: $svc still down after restart attempt $
    fi
done
```

# Code walkthrough — restart/verify/count block:

- countfile="/var/tmp/${svc}.restart_count" → one file per service, remembers failure count across separate script runs (e.g. cron every 5 min).
- count=0 then [[ -f "$countfile" ]] && count=$(cat "$countfile") → default file already exists, load the real number instead.
- -ge "$MAX_RESTARTS" → numeric "greater than or equal"; once the cap is hit, alert and continue (skip to next service) instead of restarting again.
- systemctl restart "$svc" returning 0 only means systemd accepted the req healthy.
- sleep 3 before checking → give the service time to actually start before judging it.
- systemctl is-active --quiet "$svc" → the real health check; exit 0 = act
- On success → rm -f "$countfile" resets the counter, so an unrelated future failure isn't stacked on old history.
- On failure → increment count, overwrite the file (> truncates, not appeng to stderr.

# Notes:

- --no-legend --plain — always use both when parsing systemctl list-units
- Always verify after restart with is-active --quiet — "command succeeded" ≠ "service recovered"
- Reset the failure counter only on a verified success, not just on restart
- systemctl is-active → rely only on exit code 0 (active) vs non-zero (not active); use systemctl is-failed if you specifically need to know "is it in the failed state"

# Interview-style Q&A:

## 1. What is "flapping" and why is it more dangerous than a service just being dead

A service crashing/restarting repeatedly in a fast cycle. Worse than a clean outage because: it burns CPU/IO on constant restarts, masks the real problem (looks like "it's recovering" when nothing's fixed), floods alerts (causing alert fatigueed), and repeatedly drops connections for anything depending on it.

## 2. What exit code does systemctl is-active return for active vs failed vs activating?

Only rely on: 0 = active, non-zero = not active. There's no stable dist state — use systemctl is-failed separately if you need to confirm"specifically failed" rather than just "not active."

## 3. Why isn't "the restart command ran with no error" the same as "the serv
   
systemctl restart returns 0 once systemd accepts the request — before confirming the app inside actually started successfully. It can crash again immediately after. That's why a separate verify step (sleep + is-active) is required.

## 4. Why cap restart attempts instead of retrying forever?
   
A service failing for a structural reason (bad config, missing disk, a tarting again. Retrying forever burns resources and delays the real fix — ahuman. Capping converts "silently broken forever" into "loudly escalated after N tries."

## 5. Is "this service is stateful" something systemctl can detect, or does it need human intervention?
   
Human judgment. systemctl only knows unit state (active/failed), not what the app is doing internally (mid-transaction, unflushed queue, in-memory cache). That's why the never-restart list is manually curated, not derived from systemd.
