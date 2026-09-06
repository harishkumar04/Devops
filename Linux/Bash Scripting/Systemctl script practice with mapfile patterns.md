# Script 1 — failed_service_detector.sh

``` bash
  #!/usr/bin/env bash
  set -euo pipefail

  # ─────────────────────────────────────────────
  # failed_service_detector.sh
  # Lists all systemd services currently in failed state
  # ─────────────────────────────────────────────

  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$TIMESTAMP] Scanning for failed services..."

  # Capture failed services into an array
  mapfile -t failed_services < <(
      systemctl list-units --state=failed --type=service --no-legend --plain \
      | awk '{print $1}'
  )

  # Check if any failed services found
  if [[ ${#failed_services[@]} -eq 0 ]]; then
      echo " No failed services found. All good."
      exit 0
  fi

  echo " Found ${#failed_services[@]} failed service(s):"
  echo ""

  for svc in "${failed_services[@]}"; do
      echo "  → $svc"
      # Print the last 3 journal lines for context
      journalctl -u "$svc" -n 3 --no-pager 2>/dev/null \
          | sed 's/^/     /'
      echo ""
  done

  exit 1  # Non-zero exit so callers (cron, CI) know failures exist
```
---

# Script 2 — auto_recovery.sh

```bash
  #!/usr/bin/env bash
  set -euo pipefail

  # ─────────────────────────────────────────────
  # auto_recovery.sh
  # Detects failed systemd services and attempts
  # auto-restart with full logging
  # ─────────────────────────────────────────────

  LOG_FILE="/tmp/auto_recovery_$(date '+%Y%m%d').log"
  MAX_RETRIES=3

  log() {
      local level="$1"
      local msg="$2"
      local ts
      ts=$(date '+%Y-%m-%d %H:%M:%S')
      echo "[$ts] [$level] $msg" | tee -a "$LOG_FILE"
  }

  restart_service() {
      local svc="$1"
      local attempt=0

      while [[ $attempt -lt $MAX_RETRIES ]]; do
          attempt=$(( attempt + 1 ))
          log "INFO" "Attempting restart of $svc (attempt $attempt/$MAX_RETRIES)..."

          if systemctl restart "$svc" 2>>"$LOG_FILE"; then
              sleep 2  # give it a moment to stabilize

              if systemctl is-active --quiet "$svc"; then
                  log "INFO" "$svc recovered successfully on attempt $attempt"
                  return 0
              else
                  log "WARN" "$svc restarted but is not active — may have crashed again"
              fi
          else
              log "WARN" "systemctl restart failed for $svc on attempt $attempt"
          fi
      done

      log "ERROR" " $svc could not be recovered after $MAX_RETRIES attempts"
      return 1
  }

  log "INFO" "Starting auto-recovery scan..."

  mapfile -t failed_services < <(
      systemctl list-units --state=failed --type=service --no-legend --plain \
      | awk '{print $1}'
  )

  if [[ ${#failed_services[@]} -eq 0 ]]; then
      log "INFO" "No failed services found. Nothing to recover."
      exit 0
  fi

  log "INFO" "Found ${#failed_services[@]} failed service(s): ${failed_services[*]}"

  recovered=0
  failed=0

  for svc in "${failed_services[@]}"; do
      if restart_service "$svc"; then
          (( recovered++ )) || true
      else
          (( failed++ )) || true
      fi
  done

  echo ""
  log "INFO" "Recovery summary → Recovered: $recovered | Still failed: $failed"
  log "INFO" "Full log written to: $LOG_FILE"

  # Exit 1 if any service couldn't be recovered
  [[ $failed -eq 0 ]] && exit 0 || exit 1
```
---

# Key things

- mapfile pattern — this is the clean way to get command output into an array:
```bash
      mapfile -t arr < <(command | awk '{print $1}')
```

- `-t` strips the trailing newline from each element. Without it you get nginx.service\n instead of nginx.service.

- (( count++ )) || true — arithmetic on a variable can return exit code 1 when the result is 0, which would trigger set -e and kill the script. The || true prevents that.
- sleep 2 after restart — services can briefly appear active before crashing again. A short wait catches that.
- Log file naming — /tmp/auto_recovery_20260902.log is date-stamped so you don't overwrite yesterday's run.
