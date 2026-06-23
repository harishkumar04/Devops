# Bash Debugging & Crash Analysis

## Core Debugging Tools

Before debugging any Bash script, these are your primary tools.

| Tool | Purpose |
|--------|---------|
| `bash -x script.sh` | Trace every command as it executes |
| `set -x` / `set +x` | Enable/disable tracing within a script |
| `echo "DEBUG: $var" >&2` | Inspect variable values |
| `set -euo pipefail` | Catch silent failures early |
| `trap 'echo "Failed at line $LINENO"' ERR` | Show the exact failing line |

---

# Concept 1: Diagnosing a Broken Script

## Common Failure Pattern 1: Pipe Swallowing Exit Codes

### Broken

```bash
cat file.log | grep "ERROR" | wc -l
```

If `grep` fails, the pipeline may still return success.

### Fixed

```bash
set -o pipefail

cat file.log | grep "ERROR" | wc -l
```

### Why?

`pipefail` causes the pipeline to fail if **any stage** fails.

---

## Common Failure Pattern 2: Unquoted Variables

### Broken

```bash
if [ -f $filename ]; then
```

Fails when filename contains spaces.

Example:

```bash
filename="error log.txt"
```

Expands to:

```bash
if [ -f error log.txt ]
```

which is invalid.

### Fixed

```bash
if [[ -f "$filename" ]]; then
```

---

## Common Failure Pattern 3: Empty Input Files

### Guard Against Empty Files

```bash
[[ -s "$LOG_FILE" ]] || {
    echo "Log file is empty" >&2
    exit 1
}
```

### Meaning of `-s`

```text
-s file
```

Returns true if:

- File exists
- File size > 0 bytes

---

## Common Failure Pattern 4: Wrong Field Separator

### Problem

Assuming a file is space-delimited when it actually uses tabs.

### Example

```bash
awk -F'\t' '{ print $3 }' file
```

### Why?

`-F` explicitly defines the field separator.

Common separators:

| Separator | Usage |
|------------|---------|
| `' '` | Space |
| `'\t'` | Tab |
| `','` | CSV |
| `':'` | Colon-separated files |

---

# Script 1: Broken Log Parser

## Broken Version

```bash
#!/usr/bin/env bash

LOG=$1

cat $LOG | grep ERROR | while read line; do
    timestamp=$(echo $line | awk {print $1})
    echo "Error at: " $timestamp >> report.txt
done

echo "Done. Errors found: $(wc -l report.txt)"
```

---

## Find the Bugs

### Bug 1 — Unquoted Variable

```bash
cat $LOG
```

Should be:

```bash
cat "$LOG"
```

---

### Bug 2 — Unsafe Read

```bash
while read line
```

Should be:

```bash
while IFS= read -r line
```

---

### Bug 3 — Invalid awk Program

```bash
awk {print $1}
```

Shell interprets `{}`.

Should be:

```bash
awk '{ print $1 }'
```

---

### Bug 4 — Unquoted Variable Expansion

```bash
echo "Error at: " $timestamp
```

Should be:

```bash
echo "Error at: $timestamp"
```

---

### Bug 5 — Incorrect wc Usage

```bash
wc -l report.txt
```

Output:

```text
5 report.txt
```

If you only want the count:

```bash
wc -l < report.txt
```

Output:

```text
5
```

---

# Fixed Version

```bash
#!/usr/bin/env bash

set -euo pipefail

LOG="${1:?Usage: $0 <log_file>}"

[[ -f "$LOG" ]] || {
    echo "File not found: $LOG" >&2
    exit 1
}

> report.txt

grep "ERROR" "$LOG" | while IFS= read -r line; do
    timestamp=$(echo "$line" | awk '{ print $1 }')
    echo "Error at: $timestamp" >> report.txt
done

echo "Done. Errors found: $(wc -l < report.txt)"
```

---

# Understanding the Fixes

## Parameter Validation

```bash
LOG="${1:?Usage: $0 <log_file>}"
```

If no argument is provided:

```text
Usage: ./script.sh <log_file>
```

and the script exits.

---

## Report File Reset

```bash
> report.txt
```

Equivalent to:

```bash
truncate -s 0 report.txt
```

Creates or empties the file.

---

## Reading Lines Safely

```bash
IFS= read -r line
```

Preserves:

- Leading spaces
- Trailing spaces
- Backslashes

---

# Script 2: Crash Log Analyzer

Useful for:

- Application crashes
- OOM kills
- Segmentation faults
- Kernel panics

```bash
#!/usr/bin/env bash

set -euo pipefail

LOG="${1:?Usage: $0 <crash_log>}"

[[ -f "$LOG" ]] || {
    echo "Not found: $LOG" >&2
    exit 1
}

echo "=== Crash Log Analysis: $LOG ==="
echo

echo "--- OOM Kills ---"
grep -i "out of memory\|oom.kill\|killed process" "$LOG" || echo "None found"

echo
echo "--- Segfaults ---"
grep -i "segfault\|segmentation fault" "$LOG" || echo "None found"

echo
echo "--- Kernel Panics ---"
grep -i "kernel panic\|BUG:\|Call Trace" "$LOG" || echo "None found"

echo
echo "--- Error Timeline (last 20) ---"
grep -iE "error|fatal|crash|killed" "$LOG" | tail -20

echo
echo "--- Top Offending Processes ---"
grep -oP '(?<=process )\d+' "$LOG" |
sort |
uniq -c |
sort -rn |
head -5
```

---

# Understanding the Process Extraction

## Regex

```bash
grep -oP '(?<=process )\d+'
```

### Components

| Pattern | Meaning |
|-----------|----------|
| `-o` | Output only matching text |
| `-P` | Use Perl-compatible regex |
| `(?<=process )` | Look behind for "process " |
| `\d+` | One or more digits |

### Example

Input:

```text
Killed process 1234 (java)
Killed process 5678 (python)
```

Output:

```text
1234
5678
```

---

# The ERR Trap Pattern

One of the most valuable debugging additions.

```bash
trap 'echo "ERROR at line $LINENO: $BASH_COMMAND" >&2' ERR
```

Place immediately after:

```bash
set -euo pipefail
```

Example:

```bash
#!/usr/bin/env bash

set -euo pipefail

trap 'echo "ERROR at line $LINENO: $BASH_COMMAND" >&2' ERR

cp file_that_does_not_exist backup/
```

Output:

```text
cp: cannot stat 'file_that_does_not_exist'
ERROR at line 7: cp file_that_does_not_exist backup/
```

---

# Debugging Workflow

Use this process whenever a script fails.

## Step 1: Read the Error

Often the line number is already provided.

---

## Step 2: Enable Command Tracing

```bash
bash -x script.sh
```

Or:

```bash
bash -x script.sh 2>&1 | head -50
```

View only the first 50 trace lines.

---

## Step 3: Add ERR Trap

```bash
trap 'echo "ERROR at line $LINENO: $BASH_COMMAND"' ERR
```

Pinpoints failures.

---

## Step 4: Inspect Variables

```bash
echo "DEBUG: filename=$filename" >&2
```

Use stderr so debug messages don't interfere with normal output.

---

## Step 5: Test Pipeline Stages Individually

Instead of:

```bash
cat log.txt | grep ERROR | awk '{print $1}'
```

Run:

```bash
cat log.txt
```

Then:

```bash
grep ERROR log.txt
```

Then:

```bash
grep ERROR log.txt | awk '{print $1}'
```

Identify which stage breaks.

---

# Practice Exercise

## Exercise 1: Fix the Broken Parser

1. Save the broken script.
2. Run it.
3. Observe failures.
4. Apply one fix at a time.
5. Re-run after every fix.

---

## Exercise 2: Test the Crash Analyzer

Ubuntu:

```bash
./crash_analyzer.sh /var/log/syslog
```

RHEL/CentOS:

```bash
./crash_analyzer.sh /var/log/messages
```

Kernel logs:

```bash
./crash_analyzer.sh /var/log/kern.log
```

---

## Exercise 3: Test ERR Trap

Add:

```bash
trap 'echo "Failed at $LINENO: $BASH_COMMAND"' ERR
```

Then intentionally break something:

```bash
rm file_that_does_not_exist
```

Observe the failure message.
