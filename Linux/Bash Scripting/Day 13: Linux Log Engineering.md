This day is about parsing real-world log files that aren't structured for humans — access logs, error logs, application logs — and extracting actionable data from them using 
the text tools you've built up (grep, awk, sed, sort, uniq, cut).

---

# 1. Understanding Log Formats First

Before parsing, you must know the format. The two most common are:

## Apache/Nginx Combined Log Format (CLF):

```bash
127.0.0.1 - frank [10/Jun/2026:08:45:23 +0530] "GET /api/users HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
```

Fields in order:

   $1  = IP address          (127.0.0.1)
   $2  = ident               (- usually)
   $3  = auth user           (frank or -)
   $4  = date+time           ([10/Jun/2026:08:45:23)
   $5  = timezone            (+0530)
   $6  = HTTP method+path    ("GET /api/users HTTP/1.1")
   $7  = status code         (200)
   $8  = response size       (1234)
   $9  = referer             ("-")
   $10 = user agent          ("Mozilla/5.0")

## Nginx Error Log Format:

```bash
   2026/06/16 08:45:23 [error] 1234#0: *5678 connect() failed (111: Connection refused) while connecting to upstream
```
---

# One-Liners to Know Cold

```bash
# Count requests per status code
awk '{print $9}' access.log | sort | uniq -c | sort -rn

# Top 10 IPs by request count
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -10

# Top 10 requested URLs
awk '{print $7}' access.log | sort | uniq -c | sort -rn | head -10

# All 5xx errors
awk '$9 ~ /^5/' access.log

# All 4xx errors with their URLs
awk '$9 ~ /^4/ {print $9, $7}' access.log | sort | uniq -c | sort -rn

# Requests in a time window (grep approach)
grep "16/Jun/2026:09" access.log | awk '{print $9}' | sort | uniq -c

# Total bandwidth served (sum response sizes)
awk '{sum += $10} END {print sum/1024/1024 " MB"}' access.log

# Nginx error log — count by error type
awk '/\[error\]/ {print $0}' error.log | grep -oP '\(\d+: [^)]+\)' | sort | uniq -c | sort -rn
```
---

# Key Parsing Patterns

## Extracting the HTTP method alone:

```bash
awk '{print $6}' access.log | tr -d '"' | sort | uniq -c | sort -rn
# $6 is "GET — the quote is attached, so strip it with tr
```

## Extracting just the path (no query string):

```bash
awk '{print $7}' access.log | cut -d'?' -f1 | sort | uniq -c | sort -rn
```

## Parsing date for hourly breakdown:

```bash
awk '{print $4}' access.log | cut -d: -f2 | sort | uniq -c
# $4 is [16/Jun/2026:09 — cut on : gets the hour
```

## Filtering by status code range:

```bash
awk '$9 >= 500 && $9 < 600' access.log        # all 5xx
awk '$9 == 404' access.log                    # exactly 404
awk '$9 != 200 && $9 != 301' access.log       # non-success, non-redirect
```
---

# Generating a Sample Log to Practice With

```shell
cat > /tmp/sample_access.log << 'EOF'
192.168.1.10 - - [16/Jun/2026:08:01:12 +0530] "GET /api/users HTTP/1.1" 200 2341 "-" "curl/7.68"
10.0.0.5 - - [16/Jun/2026:08:01:45 +0530] "POST /api/login HTTP/1.1" 401 89 "-" "python-requests/2.28"
192.168.1.10 - - [16/Jun/2026:08:02:01 +0530] "GET /api/orders HTTP/1.1" 500 512 "-" "curl/7.68"
10.0.0.7 - - [16/Jun/2026:08:02:33 +0530] "GET /favicon.ico HTTP/1.1" 404 0 "-" "Chrome/114"
10.0.0.5 - - [16/Jun/2026:08:03:10 +0530] "POST /api/login HTTP/1.1" 401 89 "-" "python-requests/2.28"
10.0.0.5 - - [16/Jun/2026:08:03:11 +0530] "POST /api/login HTTP/1.1" 401 89 "-" "python-requests/2.28"
192.168.1.20 - - [16/Jun/2026:09:05:22 +0530] "GET /api/users HTTP/1.1" 200 2341 "-" "Mozilla/5.0"
192.168.1.10 - - [16/Jun/2026:09:06:01 +0530] "GET /api/orders HTTP/1.1" 503 0 "-" "curl/7.68"
10.0.0.9 - - [16/Jun/2026:09:07:44 +0530] "DELETE /api/users/99 HTTP/1.1" 404 45 "-" "insomnia/2023"
192.168.1.10 - - [16/Jun/2026:09:08:00 +0530] "GET /api/orders HTTP/1.1" 500 512 "-" "curl/7.68"
EOF
```

Then run:

```shell
bash log_parser.sh /tmp/sample_access.log
```
---

# Practice Script 1 : Apache/Nginx Log Parser

Extracts status codes, top IPs, top URLs, bandwidth — a full first-look report on an access log.

```bash
   #!/usr/bin/env bash
   set -euo pipefail

   usage() {
       echo "Usage: $0 <access_log_file>" >&2
       exit 1
   }

   [[ $# -lt 1 ]] && usage
   [[ ! -f "$1" ]] && { echo "ERROR: File not found: $1" >&2; exit 1; }

   readonly LOG="$1"
   readonly TOP_N=10

   section() { echo -e "\n=== $1 ==="; }

   total_requests=$(wc -l < "$LOG")
   echo "Log file  : $LOG"
   echo "Total reqs: $total_requests"

   section "Status Code Breakdown"
   awk '{print $9}' "$LOG" \
       | grep -E '^[0-9]{3}$' \
       | sort | uniq -c | sort -rn \
       | awk '{printf "  %-6s %s requests\n", $2, $1}'

   section "Top $TOP_N IPs"
   awk '{print $1}' "$LOG" \
       | sort | uniq -c | sort -rn \
       | head -"$TOP_N" \
       | awk '{printf "  %-20s %s requests\n", $2, $1}'

   section "Top $TOP_N Requested URLs"
   awk '{print $7}' "$LOG" \
       | cut -d'?' -f1 \
       | sort | uniq -c | sort -rn \
       | head -"$TOP_N" \
       | awk '{printf "  %-50s %s hits\n", $2, $1}'

   section "Top $TOP_N 4xx Errors (Client Errors)"
   awk '$9 ~ /^4/ {print $9, $7}' "$LOG" \
       | sort | uniq -c | sort -rn \
       | head -"$TOP_N" \
       | awk '{printf "  %-6s %-50s %s hits\n", $2, $3, $1}'

   section "Top $TOP_N 5xx Errors (Server Errors)"
   awk '$9 ~ /^5/ {print $9, $7}' "$LOG" \
       | sort | uniq -c | sort -rn \
       | head -"$TOP_N" \
       | awk '{printf "  %-6s %-50s %s hits\n", $2, $3, $1}'

   section "Bandwidth (approximate)"
   awk '$10 ~ /^[0-9]+$/ {sum += $10} END {
       printf "  Total: %.2f MB\n", sum/1024/1024
   }' "$LOG"

   section "Requests per Hour"
   awk '{print $4}' "$LOG" \
       | cut -d: -f2 \
       | sort | uniq -c \
       | awk '{printf "  Hour %s: %s requests\n", $2, $1}'
```

Usage:

```shell
bash log_parser.sh /var/log/nginx/access.log
bash log_parser.sh /var/log/apache2/access.log
```
---

Practice Script 2: Top Error Counter

Specifically focused on error logs — ranks, counts, and surfaces the most frequent errors. Works on both Nginx error logs and generic application logs.

```bash
   #!/usr/bin/env bash
   set -euo pipefail

   usage() {
       echo "Usage: $0 <log_file> [top_n]" >&2
       echo "  log_file : path to error or application log" >&2
       echo "  top_n    : how many top errors to show (default: 20)" >&2
       exit 1
   }

   [[ $# -lt 1 ]] && usage
   [[ ! -f "$1" ]] && { echo "ERROR: File not found: $1" >&2; exit 1; }

   readonly LOG="$1"
   readonly TOP_N="${2:-20}"

   section() { echo -e "\n=== $1 ==="; }

   section "Error Frequency Report: $LOG"
   echo "Analysing top $TOP_N errors..."

   section "Top $TOP_N Error Lines (exact match)"
   grep -iE 'error|exception|fatal|critical|fail' "$LOG" \
       | sort | uniq -c | sort -rn \
       | head -"$TOP_N" \
       | nl \
       | awk '{printf "  #%-3s %6s hits — %s\n", $1, $2, substr($0, index($0,$3))}'

   section "Error Keyword Frequency"
   grep -ioE 'error|exception|fatal|critical|warning|timeout|refused|denied|not found' "$LOG" \
       | tr '[:upper:]' '[:lower:]' \
       | sort | uniq -c | sort -rn \
       | awk '{printf "  %-15s %s occurrences\n", $2, $1}'

   section "Errors by Hour (if timestamps present)"
   # Works for formats: [2026-06-16 09:45:23] or 2026/06/16 09:45:23 or [Mon Jun 16 09:45:23]
   grep -iE 'error|exception|fatal' "$LOG" \
       | grep -oE '[0-9]{2}:[0-9]{2}:[0-9]{2}' \
       | cut -d: -f1 \
       | sort | uniq -c \
       | awk '{printf "  Hour %s:00 — %s errors\n", $2, $1}'

   section "First Occurrence of Each Unique Error"
   grep -iE 'error|exception|fatal' "$LOG" \
       | sort -u -k1,1 \
       | head -"$TOP_N"

   section "Summary"
   total_errors=$(grep -ciE 'error|exception|fatal|critical' "$LOG" || true)
   total_lines=$(wc -l < "$LOG")
   echo "  Total log lines : $total_lines"
   echo "  Error lines     : $total_errors"
   awk -v e="$total_errors" -v t="$total_lines" \
       'BEGIN {printf "  Error rate      : %.2f%%\n", (e/t)*100}'
```
Usage:

```bash
bash top_error_counter.sh /var/log/nginx/error.log
bash top_error_counter.sh /var/log/myapp/app.log 10   # show top 10
bash top_error_counter.sh /var/log/syslog 25
```
---

# Production Practices

- Never parse logs in place on production. Copy the log to /tmp first, or use <(cat /var/log/nginx/access.log) process substitution. Log files are actively being written to.

- Use grep -c for quick counts before full analysis. On a 10GB log file, running awk immediately is slow. First check the scale: grep -c "500" access.log — if it's 3 lines, you
   don't need a full report.

- Handle the - in response size field. Nginx writes - instead of 0 for requests with no body. Your awk must guard against this: $10 ~ /^[0-9]+$/ before summing.

- Rotation awareness. On production, logs rotate (access.log, access.log.1, access.log.2.gz). For multi-file analysis:

```shell
   # Uncompressed
   cat /var/log/nginx/access.log* | awk '{print $9}' | sort | uniq -c | sort -rn

   # Including gzipped
   zcat /var/log/nginx/access.log.*.gz | awk '{print $9}' | sort | uniq -c | sort -rn
```

- Sort before uniq — always. uniq only deduplicates adjacent lines. Skipping sort gives you wrong counts. This is the single most common mistake beginners make.

- $9 vs $7 confusion. In CLF format, $7 is the URL path and $9 is the status code. Many people mix these up. When in doubt, print a few lines of the log and count fields
   manually: head -3 access.log | cat -A
---

# Quick Reference for Log Parsing

```bash
awk '{print $9}' access.log | sort | uniq -c | sort -rn   # status codes
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -10  # top IPs
awk '$9 ~ /^5/' access.log                                 # 5xx errors
awk '$9 == 404 {print $7}' access.log | sort | uniq -c    # 404 URLs
grep -c "ERROR" app.log                                    # quick error count
zcat app.log.gz | grep "ERROR" | tail -50                  # grep compressed log
```
