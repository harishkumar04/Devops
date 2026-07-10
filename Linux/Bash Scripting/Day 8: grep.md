grep stands for `Global Regular Expression Print`

It scans text and prints lines matching a pattern.

Example:

```bash
grep "ERROR" app.log
```

Output:

```text
ERROR Database connection failed
ERROR API timeout
```

grep works on:

```bash
grep "pattern" file

cat file | grep "pattern"

journalctl | grep "error"
```

---

# Sample Log File

Create:

```bash
cat > app.log << EOF
INFO Application started
INFO User login successful
WARN High memory usage
ERROR Database connection failed
INFO Request processed
ERROR API timeout
WARN Disk almost full
INFO Application stopped
EOF
```

I will use this to practice.

---

# Case Sensitivity

By default grep is case-sensitive.

Example:

```bash
grep "error" app.log # output will be nothing since there is "error" in the log file

grep -i "error" app.log # this will match all the things like "Error, ERROR, error, ErRoR" etc
# the above one is the production use
```
---

# Line Numbers

```bash
grep -n "ERROR" app.log # Very useful when debugging.

```

Output:

```text
4:ERROR Database connection failed
6:ERROR API timeout
```
---

# Literal String

`-F` (Fixed String)

Normally, grep treats the search pattern as a regular expression.

The `-F` option tells grep to treat the pattern as a literal string.

For example, without -F:

```bash
grep "1.2.3.4" file
```

`.` is a regex metacharacter meaning "any character."

With -F:

```bash
grep -F "1.2.3.4" file
```
`.` is treated as a `normal dot`, which is what you want when searching for IP addresses.

---

# Count Matches

Instead of printing:

```bash
grep -c "ERROR" app.log
```

Output:

```text
2
```

Quick incident analysis.

---

# Inverse Matching

Show everything EXCEPT matching lines.
Useful to remove noise

```bash
grep -v "INFO" app.log
```

Output:

```text
WARN High memory usage
ERROR Database connection failed
ERROR API timeout
WARN Disk almost full
```
---

# Exact Word Match

Problem:

```bash
grep "error"
```

Matches:

```text
error
errors
erroring
```

Sometimes unwanted.

Use:

```bash
grep -w "error" # exact match of the word
```

Matches only:

```text
error
```

---

# Multiple Patterns

Method 1:

```bash
grep -E "ERROR|WARN" app.log
```

Output:

```text
WARN High memory usage
ERROR Database connection failed
ERROR API timeout
WARN Disk almost full
```
---

# Recursive Search

Search entire directory tree.

```bash
grep -r "database" .
```

Search:

```text
current directory
subdirectories
all files
```
---

# Show Only File Names

```bash
grep -rl "database" .
```

Output:

```text
./config.yaml
./app.env
```

Useful in huge codebases.

---

# Exclude Directories

Very important.

Bad:

```bash
grep -r "TODO" .
```

Searches:

```text
.git
node_modules
vendor
dist
```
This is slow.

## Production Use:

```bash
grep -r \
--exclude-dir=node_modules \
--exclude-dir=.git \
"TODO" .
```

---

# Context Lines

Show lines around match. Critical for log investigation.

Before:

```bash
grep -B 2 "ERROR" app.log
```

After:

```bash
grep -A 2 "ERROR" app.log
```

Both:

```bash
grep -C 2 "ERROR" app.log
```

---

# Match Beginning of Line

Regex:

```bash
^ # meaning -> Start of line
```

Example:

```bash
grep "^ERROR" app.log
```

Matches:

```text
ERROR Database connection failed
ERROR API timeout
```

---

# Match End of Line

Regex:

```bash
$
```

Example:

```bash
grep "failed$" app.log
```

Matches:

```text
ERROR Database connection failed
```

---

# Dot (.)

Matches any single character.

```bash
grep "E.ROR"
```

Matches:

```text
ERROR
EXROR
E1ROR
```
---

# Character Classes

## Match digits:

```bash
grep "[0-9]"
```

Example:

```text
user1
user2
user99
```

---

## Match lowercase:

```bash
grep "[a-z]"
```

## Match uppercase:

```bash
grep "[A-Z]"
```

---

# Extended Regex

Always use:

```bash
grep -E
```

Instead of older:

```bash
egrep
```
---

Example:

```bash
grep -E "ERROR|WARN"
```

---

# Quantifiers

## Zero or More

```bash
grep -E "ab*"
```

Matches:

```text
a
ab
abb
abbb
```

---

## One or More

```bash
grep -E "ab+"
```

Matches:

```text
ab
abb
abbb
```

Not:

```text
a
```

---

## Optional

```bash
grep -E "colou?r"
```

Matches:

```text
color
colour
```

---

# Production Regex Examples

IP Address

```bash
grep -E "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"
```

---

HTTP Status Codes

```bash
grep -E "HTTP/[0-9]\.[0-9]"
```

---

Email

```bash
grep -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+"
```

---

# Exit Codes (Important)

grep is frequently used in automation.

Match found:

```bash
0
```

No match:

```bash
1
```

Error:

```bash
2
```

Example:

You don't care about output.
You care about success/failure.

```bash
if grep -q "ERROR" app.log; then
    echo "Errors found" 
fi
```
---

# Script 1 — Error Log Scanner

## Goal

Extract:

```text
ERROR
WARN
```

from logs.

---

Create:

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-}"

if [[ -z "$LOG_FILE" ]]; then
    echo "Usage: $0 <logfile>" >&2
    exit 1
fi

if [[ ! -f "$LOG_FILE" ]]; then
    echo "File not found: $LOG_FILE" >&2
    exit 1
fi

echo "===== WARNINGS & ERRORS ====="

grep -E "ERROR|WARN" "$LOG_FILE" || true
```
---

# Production Improvements

Count errors:

```bash
error_count=$(grep -c "ERROR" "$LOG_FILE" || true)
warn_count=$(grep -c "WARN" "$LOG_FILE" || true)
```

Print summary:

```bash
echo "Errors : $error_count"
echo "Warnings : $warn_count"
```

---

# Script 2 — Failed Login Finder
sample log:

```bash
cat > auth.log << EOF
Failed password for root from 10.0.0.1
Accepted password for ubuntu from 10.0.0.2
Failed password for admin from 10.0.0.3
Failed password for root from 10.0.0.4
EOF
```

---

Script:

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-auth.log}"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "Log file not found" >&2
    exit 1
fi

echo "===== FAILED LOGIN ATTEMPTS ====="

grep "Failed password" "$LOG_FILE"

echo
echo "Total failed attempts:"

grep -c "Failed password" "$LOG_FILE"
```

---

# Production Version

Show unique attacking IPs:

```bash
grep "Failed password" auth.log \
| awk '{print $NF}' \
| sort \
| uniq -c \
| sort -nr
```

Output:

```text
5 192.168.1.100
3 10.0.0.5
2 172.16.0.7
```

This is exactly the type of command used during security investigations.

---


# Production grep Knowledge Checklist

```bash
grep -i
grep -n
grep -c
grep -v
grep -w
grep -r
grep -rl
grep -E
grep -q
grep -A
grep -B
grep -C
grep -F
```

Regex:

```bash
^
$
.
[0-9]
[a-z]
[A-Z]
*
+
?
|
```

And most importantly:

```bash
if grep -q ...
```
