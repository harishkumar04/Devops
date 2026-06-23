## Concept 1: Real-Time Log Watching with `tail -f`

`tail -f` follows a file live — it blocks and prints new lines as they're appended.

```bash
tail -f /var/log/syslog
```

In a script, combine it with a `while read` loop to react to each new line:

```bash
tail -f /var/log/app.log | while IFS= read -r line; do
    echo "New entry: $line"
done
```

### Why `IFS=` and `-r` Matter

```bash
while IFS= read -r line
```

| Option | Purpose |
|----------|----------|
| `IFS=` | Prevents stripping leading/trailing whitespace |
| `-r` | Prevents backslash interpretation |

---

## Concept 2: Pattern Matching on Live Lines

Inside the loop, filter lines using `grep` or Bash regex.

### Using grep

```bash
tail -f /var/log/app.log | while IFS= read -r line; do
    if echo "$line" | grep -qi "error"; then
        echo "[ALERT] Error detected: $line" >&2
    fi
done
```

### Using Bash Built-In Regex

Faster because it avoids spawning a subprocess:

```bash
if [[ "$line" =~ [Ee][Rr][Rr][Oo][Rr] ]]; then
```

---

## Concept 3: Alert Destinations

There are three common ways to send alerts.

### 1. Write to a File

```bash
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $line" >> /var/log/alerts.log
```

### 2. Print to stderr

Useful because stderr can be separated from normal output.

```bash
echo "ALERT: $line" >&2
```

### 3. Send to a Webhook

```bash
curl -s -X POST "$WEBHOOK_URL" -d "message=$line"
```

> Day 37 covers webhooks in detail.

---

# Script 1: Real-Time Log Watcher

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-/var/log/syslog}"

[[ -f "$LOG_FILE" ]] || {
    echo "File not found: $LOG_FILE" >&2
    exit 1
}

echo "[INFO] Watching: $LOG_FILE"

tail -f "$LOG_FILE" | while IFS= read -r line; do
    echo "[$(date '+%H:%M:%S')] $line"
done
```

### Run

```bash
./log_watcher.sh /var/log/app.log
```

---

# Script 2: Keyword Alert System

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:?Usage: $0 <log_file> <keyword>}"
KEYWORD="${2:?Keyword required}"
ALERT_LOG="/tmp/alerts_$(date '+%Y%m%d').log"

[[ -f "$LOG_FILE" ]] || {
    echo "File not found: $LOG_FILE" >&2
    exit 1
}

echo "[INFO] Watching '$LOG_FILE' for keyword: '$KEYWORD'"

tail -f "$LOG_FILE" | while IFS= read -r line; do
    if echo "$line" | grep -qi "$KEYWORD"; then
        msg="[$(date '+%Y-%m-%d %H:%M:%S')] ALERT | keyword='$KEYWORD' | $line"
        echo "$msg" | tee -a "$ALERT_LOG" >&2
    fi
done
```

### Run

```bash
./keyword_alert.sh /var/log/app.log ERROR
```

---

# Key Patterns to Remember

| Pattern | Purpose |
|----------|----------|
| `tail -f file \| while IFS= read -r line` | Process live log entries |
| `grep -qi "pattern"` | Case-insensitive match without output |
| `tee -a file >&2` | Write to alert log and stderr simultaneously |
| `"${1:?message}"` | Require argument or exit with message |
| `date '+%Y-%m-%d %H:%M:%S'` | Generate timestamps |

---

# Practice Exercise

## Step 1: Generate Fake Log Traffic

Run in Terminal 1:

```bash
while true; do
    echo "$(date) INFO normal traffic" >> /tmp/test.log
    sleep 1
done
```

---

## Step 2: Start the Alert Script

Run in Terminal 2:

```bash
./keyword_alert.sh /tmp/test.log ERROR
```

---

## Step 3: Inject an Error

Run in another terminal:

```bash
echo "$(date) ERROR database connection failed" >> /tmp/test.log
```

---

## Step 4: Verify

Check that:

- Alert appears on screen
- Alert is written to:

```bash
ls /tmp/alerts_*.log
```

View contents:

```bash
cat /tmp/alerts_*.log
```

---
