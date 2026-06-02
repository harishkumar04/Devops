# awk basics

awk reads input line by line. Each line is a record. Each word separated by whitespace is a field.

```shell
  line:   "root  x  0  0  root  /root  /bin/bash"
  fields:   $1   $2 $3 $4   $5    $6       $7
```
`$0 = the entire line. $1, $2... = individual fields.`

```shell
echo "harish 25 bangalore" | awk '{print $1}'    # harish
echo "harish 25 bangalore" | awk '{print $3}'    # bangalore
echo "harish 25 bangalore" | awk '{print $0}'    # harish 25 bangalore
```
---

# Structure

```shell
 awk 'pattern { action }' file
```

- pattern — which lines to process (optional, if omitted = all lines)
- action — what to do with those lines

```shell
  awk '{ print $1 }' /etc/passwd          # print field 1 of every line
  awk '/root/ { print $0 }' /etc/passwd   # print lines containing "root"
  awk 'NR==1 { print $0 }' /etc/passwd   # print only line 1
```
---

# Built-in variables

NR    # current line number (Number of Records)
NF    # number of fields in current line
FS    # field separator (default: whitespace)
OFS   # output field separator

```shell
awk '{ print NR, $1 }' /etc/passwd       # line number + first field
awk '{ print NF }' file.txt              # how many fields per line
awk 'NR>=2 && NR<=5 { print }' file     # print lines 2 to 5
```
---

# Custom field separator with -F

Default separator is whitespace. Use -F to change it:

`/etc/passwd uses : as separator`

```shell
  awk -F: '{ print $1 }' /etc/passwd          # usernames only
  awk -F: '{ print $1, $6 }' /etc/passwd      # username + home dir
  awk -F, '{ print $2 }' data.csv             # second column of CSV
```

-F accepts any character or regex

```shell
awk -F: ...      # colon
awk -F, ...      # comma
awk -F'|' ...    # pipe (quoted to prevent shell interpretation)
awk -F'\t' ...   # tab
awk -F'[,:]' ... # either comma OR colon
```

**The separator is just "what character should I split on" — we can use anything our data uses.**

## Demo 1

The `/etc/passwd` looks like this:

```shell
root:x:0:0:root:/root:/bin/bash
harish:x:1000:1000::/home/harish:/bin/bash
nobody:x:65534:65534::/nonexistent:/usr/sbin/nologin
```

### awk without -F:

```shell
awk '{ print $1 }' /etc/passwd
# root:x:0:0:root:/root:/bin/bash
# harish:x:1000:1000::/home/harish:/bin/bash
```
`awk sees no whitespace, so the entire line is $1. Useless.`

### With -F: — colon as separator

`Now awk splits each line on :`

```python
root:x:0:0:root:/root:/bin/bash
$1  $2 $3 $4 $5   $6      $7
```

```shell
awk -F: '{ print $1 }' /etc/passwd
# root
# harish
# nobody

awk -F: '{ print $1, $6 }' /etc/passwd
# root /root
# harish /home/harish
# nobody /nonexistent
```
**The comma between $1, $6 in the print statement adds a space between them in the output.**

## Demo 2 (with CSV Files)
 
### With -F, — comma as separator (CSV)

Let's say we have servers.csv:

```csv
   hostname,ip,status
   web-01,192.168.1.10,active
   db-01,192.168.1.20,inactive
```

```python
web-01,192.168.1.10,active
$1        $2        $3
```
```shell   
awk -F, '{ print $2 }' servers.csv
# ip
# 192.168.1.10
# 192.168.1.20
```

`Skip the header line with NR>1:`

```shell
awk -F, 'NR>1 { print $2 }' servers.csv
# 192.168.1.10
# 192.168.1.20
```
---

# BEGIN and END blocks

```shell
  awk 'BEGIN { print "--- Start ---" }
       { print $1 }
       END { print "--- Done. Lines: " NR }' file
```

- BEGIN runs once before any input is read — use for headers, setup
- { } runs once per line for every line in the file
- END runs once after the last line is processed

## Demo example

Say file contains:

```python
harish bangalore 25
alice mumbai 30
bob delhi 28
```

### Phase 1 — BEGIN (no file read yet):

```shell
   prints: --- Start ---
```

### Phase 2 — per line (runs 3 times):

```shell
line 1: print $1  →  harish
line 2: print $1  →  alice
line 3: print $1  →  bob
```

### Phase 3 — END (all lines processed, NR = 3):

```python
prints: --- Done. Lines: 3
```

### Final output:

```shell
--- Start ---
harish
alice
bob
--- Done. Lines: 3
```

`Why NR is available in END`
NR keeps incrementing as awk reads each line. After all lines are processed it holds the total count. So in END, NR = total number of lines — useful for summaries.

---

# Conditions inside awk

```shell
awk -F: '$3 >= 1000 { print $1 }' /etc/passwd      # users with UID >= 1000
awk '$5 > 80 { print $1, $5 }' disk.txt            # lines where field 5 > 80
awk '/ERROR/ && /timeout/ { print }' app.log        # lines with both words
```
---

# Aggregation

## sum a column

```shell
awk '{ sum += $3 } END { print "Total:", sum }' data.txt
```

## count matching lines

```shell
awk '/ERROR/ { count++ } END { print "Errors:", count }' app.log
```

## average

```shell
awk '{ sum += $2; count++ } END { print "Avg:", sum/count }' data.txt
```
---

# AWK Production Use

```shell
# print last field of every line
awk '{ print $NF }' file

# print second-to-last field
awk '{ print $(NF-1) }' file

# print lines between two patterns
awk '/START/,/END/ { print }' file

# replace a field value
awk -F: 'BEGIN{OFS=":"} $1=="root" { $6="/var/root" } { print }' /etc/passwd

# count occurrences of each value in column 1
awk '{ count[$1]++ } END { for (k in count) print count[k], k }' file | sort -rn
```
---

## awk Quick Reference

| Concept          | Syntax                              |
|------------------|-------------------------------------|
| Print field      | `awk '{ print $2 }'`                |
| Custom separator | `awk -F:` or `awk -F,`              |
| Line number      | `NR`                                |
| Field count      | `NF`                                |
| Last field       | `$NF`                               |
| Condition        | `awk '$3 > 10 { print }'`           |
| Sum column       | `awk '{ sum+=$2 } END { print sum }'` |
| Pass shell var   | `awk -v name="$var"`                |
| BEGIN/END        | Setup and summary blocks            |

### Example

```bash
# Print second column
awk '{ print $2 }' file.txt

# Use colon as field separator
awk -F: '{ print $1 }' /etc/passwd

# Print line number and content
awk '{ print NR, $0 }' file.txt

# Print last field
awk '{ print $NF }' file.txt

# Print lines where third field > 10
awk '$3 > 10 { print }' file.txt

# Sum second column
awk '{ sum+=$2 } END { print sum }' file.txt

# Pass shell variable
awk -v name="$var" '{ print name, $1 }' file.txt

# BEGIN and END blocks
awk 'BEGIN { print "Start" } { print $1 } END { print "Done" }' file.txt
```
---

# Practice script 1: CSV Analyzer

Create a test CSV to use for this:

```shell
  cat > servers.csv << 'EOF'
  hostname,ip,status
  web-01,192.168.1.10,active
  web-02,192.168.1.11,active
  db-01,192.168.1.20,inactive
  cache-01,192.168.1.30,active
  EOF
```

```bash
#!/usr/bin/env bash
# csv_analyzer.sh — Parse and summarize a CSV file
# Usage: ./csv_analyzer.sh <file.csv>

  if [[ $# -eq 0 ]]; then
      echo "Usage: $0 <file.csv>" >&2
      exit 1
  fi

  file="$1"

  [[ ! -f "$file" ]] && { echo "ERROR: file not found: $file" >&2; exit 1; }

  echo "=== CSV Summary: $file ==="
  echo "Total rows: $(awk 'NR>1' "$file" | wc -l)"
  echo ""
  echo "--- Data (formatted) ---"
  awk -F, 'NR==1 {
      printf "%-20s %-20s %-20s\n", $1, $2, $3
      print "------------------------------------------------------------"
  }
  NR>1 {
      printf "%-20s %-20s %-20s\n", $1, $2, $3
  }' "$file"
```

## Explanation

###  $(awk 'NR>1' "$file" | wc -l)
  
awk 'NR>1' "$file" —> prints every line where line number > 1. 

`No action block means default action = print.` This skips the header row and outputs all data rows.

| wc -l — counts the lines piped to it. wc = word count, -l = count lines.

###  printf "%-20s %-20s %-20s\n", $1, $2, $3

printf is formatted printing — like echo but with precise control over layout.

```shell
Format string: "%-20s %-20s %-20s\n"
```
Each %-20s means:

- %s — insert a string here
- 20 — reserve 20 characters of width
- `-` —> left-align (without - it right-aligns)

So each field gets exactly 20 characters of space, left-aligned — columns line up perfectly regardless of content length.

```python
%-20s with "web-01"        → "web-01              " (padded to 20)
%-20s with "192.168.1.10"  → "192.168.1.10        " (padded to 20)
```
\n = newline at the end.

### two awk blocks

### Result

```text
hostname             ip                   status
------------------------------------------------------------
web-01               192.168.1.10         active
web-02               192.168.1.11         active
db-01                192.168.1.20         inactive
cache-01             192.168.1.30         active
```

---

# Practice script 2: CPU Usage Parser

```bash
  #!/usr/bin/env bash
  # cpu_parser.sh — Extract and rank top CPU-consuming processes

  threshold="${1:-1.0}"    # default: show processes using > 1% CPU

  echo "=== Processes using more than ${threshold}% CPU ==="
  echo ""
  printf "%-8s %-8s %-8s %s\n" "PID" "CPU%" "MEM%" "COMMAND"
  echo "----------------------------------------"

  ps aux --no-headers | awk -v thresh="$threshold" '
  $3 > thresh {
      printf "%-8s %-8s %-8s %s\n", $2, $3, $4, $11
  }' | sort -k2 -rn

  echo ""
  echo "Total processes: $(ps aux --no-headers | wc -l)"
```

## Explanation

## Passing variable from the shell to awk env

`-v thresh="$threshold"` — passes a shell variable into awk.

`awk runs in its own separate environment. Shell variables don't exist inside awk:`
The above line creates an awk variable called thresh and assigns the shell value to it. Now inside awk, thresh exists and holds 1.0

```SHELL
threshold="1.0"

awk '$3 > threshold { print }' file    # WRONG — awk has no variable called threshold
# threshold is just an undefined awk variable = 0
```

`We need -v to pass a shell variable into awk's environment.`

**We can pass multiple variables too**

```shell
awk -v thresh="$threshold" -v user="$username" '...'
```

### threshold="${1:-1.0}"

If $1 is given use it, otherwise default to 1.0 (concept from Day 4).

### ps aux --no-headers

ps aux = list all processes with CPU/memory stats.
--no-headers = skip the column header line so awk only sees data.

### awk -v thresh="$threshold" '$3 > thresh { printf ... }'

For each process line, if CPU% ($3) is greater than the threshold, print it formatted.

###  | sort -k2 -rn

Sort the awk output: (**important**)

```python
-k2 = sort by column 2 (CPU%)
-r = reverse (highest first)
-n = numeric sort (so 10 > 9, not "9" > "10" alphabetically)
```
---
