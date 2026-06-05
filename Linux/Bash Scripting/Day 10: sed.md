# What is sed
sed = stream editor. 

- It reads input line by line, applies transformations, and outputs the result. 
- Unlike awk (which is for data extraction), sed is primarily for text modification — find and replace, delete lines, insert text.

# Structure

```shell
sed 'command' file
```

# Example file for the practice

```shell
cat > server.log << 'EOF'
   Server starting on host=localhost
   port=8080 is now open
   ERROR: connection failed on port=8080
   debug mode is debug=false
   WARNING: retrying connection to port=8080

   ERROR: timeout after 30s
   Server ready on localhost
   EOF
```
---

# 1. Substitution 

## Structure :

```shell
s/old/new/g
```

```shell
# replace first occurrence per line only
sed 's/port=8080/port=9090/' server.log
# line 2: "port=9090 is now open"
# line 3: "ERROR: connection failed on port=9090"  ← only first match changed

# replace ALL occurrences per line
sed 's/port=8080/port=9090/g' server.log
# line 3 had port=8080 once, so same result here
# but if a line had port=8080 twice, /g catches both

# case insensitive
sed 's/error/ALERT/gi' server.log
# "ERROR: connection failed..." → "ALERT: connection failed..."
# "ERROR: timeout..."          → "ALERT: timeout..."
```

`None of these touch the actual file — output goes to terminal only.`

# Important rule 

The rule is simple: `pick a delimiter that doesn't appear in your text. Any character works — / | # @ `, are all valid:

```shell
sed 's#old#new#g' file
sed 's@old@new@g' file
sed 's,old,new,g' file
```
In practice, / for normal text and | for paths/URLs covers 99% of cases. (see the script 1 below)

---

# 2. Inline editing -i and -i.bak

```shell
# modify file in place — original is gone
sed -i 's/localhost/prodserver01/g' server.log
cat server.log
# "Server starting on host=prodserver01"
# "Server ready on prodserver01"

# modify file but save original as server.log.bak
sed -i.bak 's/localhost/prodserver01/g' server.log
cat server.log      # modified version
cat server.log.bak  # original preserved

# Always use -i.bak in production. If your regex was wrong you can restore:
cp server.log.bak server.log    # undo
```
---

# 3. Deleting lines

```shell
# delete lines containing ERROR
sed '/ERROR/d' server.log
# Output — ERROR lines are gone:
# Server starting on host=localhost
# port=8080 is now open
# debug mode is debug=false
# WARNING: retrying connection to port=8080
#
# Server ready on localhost

# delete empty lines (^ = line start, $ = line end, nothing between = empty)
sed '/^$/d' server.log
# the blank line between WARNING and ERROR disappears

# chain both — delete ERROR lines AND empty lines
sed -e '/ERROR/d' -e '/^$/d' server.log
# Server starting on host=localhost
# port=8080 is now open
# debug mode is debug=false
# WARNING: retrying connection to port=8080
# Server ready on localhost

# delete specific line numbers
sed '3d' server.log          # delete line 3
sed '3,5d' server.log        # delete lines 3 through 5
```
---

# 4. Printing specific lines with -n

Without -n, sed prints every line. -n suppresses that — only explicit p commands produce output.

```shell
# print only line 3
sed -n '3p' server.log
# ERROR: connection failed on port=8080

# print lines 2 to 4
sed -n '2,4p' server.log
# port=8080 is now open
# ERROR: connection failed on port=8080
# debug mode is debug=false

# print only lines matching a pattern
sed -n '/ERROR/p' server.log
# ERROR: connection failed on port=8080
# ERROR: timeout after 30s

# print lines between two patterns (inclusive)
sed -n '/WARNING/,/ERROR/p' server.log
# WARNING: retrying connection to port=8080
#                                            ← empty line included
# ERROR: timeout after 30s
```

This last one is extremely useful in production — extracting a section of a log between two markers.

---

# 5.Address ranges

```shell
sed '1s/old/new/' file         # substitute only on line 1
sed '5,10s/old/new/g' file     # substitute only on lines 5-10
sed '/START/,/END/d' file      # delete everything between START and END
```
---

# Practice script 1 :  Config Updater

Created this file first

```shell
cat > app.conf << 'EOF'
host=localhost
port=8080
debug=false
log_level=info
EOF
```

```shell
#!/usr/bin/env bash
# config_updater.sh — Safely update a key=value in a config file
# Usage: ./config_updater.sh <file> <key> <newvalue>

if [[ $# -ne 3 ]]; then
     echo "The number arguments should be 3" >&2
     exit 1
fi

file="$1"
key="$2"
value="$3"

[[ ! -f $file ]] && {echo "Error: File not found: $file" >&2; exit 1;}

  # check key exists in file
  if ! grep -q "^${key}=" "$file"; then
      echo "ERROR: key '$key' not found in $file" >&2
      exit 1
  fi

  # backup and update
  sed -i.bak "s|^${key}=.*|${key}=${value}|" "$file"
  echo "Updated '$key' to '$value' in $file"
  echo "Backup saved as ${file}.bak"
```

## Learnings (important)

### `&&` statement

```shell
[[ ! -f $file ]] && {echo "Error: File not found: $file" >&2; exit 1;}
```

- `[[ ! -f $file ]]` -> This sets exit code 0 (true) or 1 (false).
- `&&` -> Only runs the right side if the left side succeeded (exit code 0). So the right side only runs when the file does NOT exist.
- `{ echo ...; exit 1; }`

   **The { } groups multiple commands into one block so && treats them as a single unit.**
  
```python
   Without { }:

   [[ ! -f "$file" ]] && echo "ERROR..." >&2; exit 1
   #                                          ^^^^^^^^^^
   #                     this runs ALWAYS — semicolon ends the && chain

   With { }:

   [[ ! -f "$file" ]] && { echo "ERROR..." >&2; exit 1; }
   #                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   #                      both commands only run if condition is true

   Note the semicolon before } — it's required syntax in Bash.
```

The alternative if statement is:

```shell
 if [[ ! -f "$file" ]]; then
       echo "ERROR: file not found: $file" >&2
       exit 1
   fi
```

### if statment with grep

```shell
 # check key exists in file
     if ! grep -q "^${key}=" "$file"; then
         echo "ERROR: key '$key' not found in $file" >&2
         exit 1
     fi
```

#### grep -q "^${key}="

`-q = quiet`, no output, just sets exit code:
- 0 = found a match
- 1 = no match found

Say key="port". This expands to: `grep -q "^port=" "$file"`

```python
The regex ^port= means:

   - ^ = start of line
   - port= = literal text
```

`So it only matches lines where port= appears at the very beginning.` 

This prevents false matches:

```shell
   # file contains:
   report=daily      # ^port= does NOT match — 'port' is not at line start
   port=8080         # ^port= MATCHES
```

#### "^${key}=" "$file" what is the empty space after equal to is?

 That space is just the separator between two arguments to grep.

grep syntax is always: 

```shell
grep [options] pattern file
```
The space just separates them — same as:

```shell
   ls -l /tmp
   #      ^
   #      space separating the flag from the path
```

If it were inside the quotes it would be part of the pattern:

```shell
grep -q "^${key}= " "$file"   # now searching for "port= " with a space after =
grep -q "^${key}=" "$file"    # searching for "port=" — no space in pattern
```

#### what happens if i do this "^${key}="$file"?

`Bash would see this as one single argument, not two.`

`Bash concatenates adjacent quoted strings with no space between them:`

```python
   "^${key}="   +   "$file"   =   "^port=app.conf"
```
So grep receives ^port=app.conf as the pattern and no file argument. 
It would then wait for stdin input (since no file was given) or search for the literal string

`The space is what tells Bash "first argument ends here, second argument starts here":`

```shell
   grep -q "^${key}=" "$file"
   #                 ^
   #                 space = argument boundary
```

Without the space there is no boundary — Bash glues them together into one argument.

### sed commands

```shell
sed -i.bak "s|^${key}=.*|${key}=${value}|" "$file"
```
- `Double quotes — shell expands $key and $value before sed runs`

#### why "|" instead of /"
```shell
sed "s/^port=.*/port=9090/"    # works but ugly if value contains /
sed "s|^port=.*|port=9090|"    # cleaner — | as delimiter avoids conflicts
```
If value were something like /var/log/app, using / as delimiter would break:

```shell
sed "s/^path=.*/path=/var/log/app/"   # sed sees 5 slashes — broken
sed "s|^path=.*|path=/var/log/app|"   # fine — | is the delimiter, / is literal
```

#### regex

The regex: `^port=.*`
  - `^port=` = line starts with port=
   - `.` = match any single character
   - `*` = repeat that (any char) zero or more times

So after `port=` is matched first it will match `8` from `8080` beacuse of `.` and then beacuse of `*` it will match `0` then `8` the `0` etc.

##### what will happen if I just do sed "s|^port=*|port=9090|"

```shell
sed "s|^port=*|port=9090|"
```
`*` applies to the character before it and here it's `=`, so it means "zero or more = characters"

so it Matches:

```shell
port (because = can appear zero times)
port= 
port=== 
```

So for: `port=8080` 
It matches only:

```shell
port=
```

Then replaces it with:
```shell
port=9090
```

And leaves:
```shell
8080
```

Result:
```python
port=90908080  (wrong we wanted port=9090)
```

##### what will happen if I just do sed "s|^port=.|port=9090|"

```shell
sed "s|^port=.|port=9090|"
```

`. = exactly ONE character`

So it matches `port=` `plus exactly one character after it — just 8.`

Replaces port=8 with port=9090, leaves 080 behind.

```python
port=8080  →  port=9090080  ❌
```
##### what will happen if I just do sed "s|^port=|port=9090|"

`Empty — replaces only port=`

Matches just port= with nothing after it.

```python
port=8080  →  port=90908080  ❌
```
The port= part gets replaced, but 8080 stays — appended right after the new value.

---

# Practice Script 2 : Log Sanitizer

Create a sample file 

```shell
  cat > raw.log << 'EOF'
  2026-06-02 10:01 User login from 192.168.1.10
  2026-06-02 10:02 Auth token=abc123xyz accepted
  2026-06-02 10:03 password=secret123 submitted

  2026-06-02 10:04 Connection from 10.0.0.5 established
  EOF
```

```shell
#!/usr/bin/env bash
# log_sanitizer.sh — Remove sensitive data from log files
# Usage: ./log_sanitizer.sh <input.log> <output.log>

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <input.log> <output.log>" >&2
    exit 1
fi

input="$1"
output="$2"

[[ ! -f "$input" ]] && { echo "ERROR: file not found: $input" >&2; exit 1; }

sed \
  -e 's/password=[^ ]*/password=[REDACTED]/gi' \
  -e 's/token=[^ ]*/token=[REDACTED]/gi' \
  -e 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/[IP]/g' \
  -e '/^$/d' \
  "$input" > "$output"

echo "Sanitized log written to: $output"
echo "Original lines: $(wc -l < "$input")"
echo "Output lines  : $(wc -l < "$output")"
```

Multiple -e flags let you chain sed commands. Each -e is one operation applied in sequence.

## Learnings

### s/password=[^ ]*/password=[REDACTED]/gi

Pattern: `password=[^ ]*`

- password= — literal text
- `[^ ]` — any character that is NOT a space (^ inside [] means NOT)
- `*` — zero or more of those non-space characters

So `[^ ]*` matches everything after = until a space or end of line — the actual password value.

```python
password=secret123   →  password=[REDACTED]
password=abc def     →  password=[REDACTED] def   ← stops at space
```

Flags: 
- `g` = replace all occurrences per line
- `i` = case insensitive (catches Password=, PASSWORD=)

### 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/[IP]/g'

This matches an IPv4 address. Breaking it apart:

`[0-9]\{1,3\}` — one to three digits:
 - `[0-9]` = any digit
 - `\{1,3\}` = between 1 and 3 of them (matches 1, 10, 192)

`\.` — a literal dot (\ escapes it —> without backslash . means "any character")

The full pattern repeats four times separated by \.:

```python
   [0-9]\{1,3\}  \.  [0-9]\{1,3\}  \.  [0-9]\{1,3\}  \.  [0-9]\{1,3\}
      1-3 digits   .   1-3 digits   .   1-3 digits   .   1-3 digits

   192.168.1.10   →  [IP]
   10.0.0.5       →  [IP]
```

**Note: the \{ \} is basic regex syntax (BRE). In extended regex (-E) you'd write {1,3} without backslashes.**

### '/^$/d'

Delete empty lines. 
^ = start of line, $ = end of line, nothing between = empty line.

### "$input" > "$output"

sed reads from $input, all four commands are applied to every line, result goes to $output. Original file untouched.

---

# Key sed patterns for production

```shell
# remove leading whitespace
sed 's/^[[:space:]]*//' file

# remove trailing whitespace
sed 's/[[:space:]]*$//' file

# remove both
sed 's/^[[:space:]]*//;s/[[:space:]]*$//' file

# comment out a line containing a pattern
sed '/pattern/s/^/#/' file

# uncomment a line
sed '/pattern/s/^#//' file

# print line count without wc
sed -n '$=' file
```
---

# Summary

| Command | What it does |
|----------|-------------|
| `s/old/new/g` | Replace all occurrences |
| `-i` | Edit file in place |
| `-i.bak` | Edit in place + backup |
| `/pattern/d` | Delete matching lines |
| `^$/d` | Delete empty lines |
| `-n '5,10p'` | Print only lines 5–10 |
| `-e` | Chain multiple commands |
| `s\|path\|path\|` | Use `\|` when pattern contains `/` |

---
