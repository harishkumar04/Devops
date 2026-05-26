# 1. for Loop

## Loop over a list

```shell
for item in one two three; do
    echo "$item"
done
```
## Loop over files

```shell
for file in /var/log/*.log; do
      echo "Found: $file"
done
```

## C-style loop (when you need a counter)

```shell
  for (( i=1; i<=5; i++ )); do
      echo "Number: $i"
  done
```
## Loop over arguments

```shell
  for arg in "$@"; do
      echo "$arg"
  done
```

---

# 2. while loop

Runs as long as the condition is true:

```shell
  count=1
  while [[ $count -le 5 ]]; do
      echo "Count: $count"
      count=$((count + 1))
  done
```

## Read a file line by line — production pattern

```shell
  while IFS= read -r line; do
      echo "$line"
  done < /etc/hosts           # stdin for the while loop
```
  - IFS (Internal Field Separator) = — prevents stripping leading/trailing whitespace
  - -r — prevents backslash interpretation
  - < file — feeds the file as input to the loop

### Why IFS?

When read reads a line, it strips leading and trailing characters that match IFS:

#### WITHOUT IFS — whitespace gets stripped

```shell
   while read -r line; do
       echo "$line"
   done < /etc/hosts

   # "    127.0.0.1   localhost" becomes "127.0.0.1   localhost"
   # leading spaces stripped
```

#### WITH IFS

```shell
   while IFS= read -r line; do
       echo "$line"
   done < /etc/hosts

   # "    127.0.0.1   localhost" stays exactly as-is
   # lading spaces preserved
```
   IFS= sets IFS to empty for the duration of read — nothing gets stripped.
   
   ---
   
 ###  Without -r — backslashes get consumed
 
 A file containing this line:
 
```shell
 path = C:\new\folder
```

 #### WITHOUT -r

```shell
   while IFS= read line; do
       echo "$line"
   done < file.txt
   # prints: path = C:
   ewolder
   # \n became a newline, \f became nothing — backslashes interpreted
```

#### WITH -r

```shell
   while IFS= read -r line; do
       echo "$line"
   done < file.txt
   # prints: path = C:\new\folder
   # backslashes treated as literal characters
```
   -r = raw mode. Backslashes are not escape characters, they're just
   backslashes.

---

# 3. Break and continue

```shell
for i in 1 2 3 4 5; do
       [[ $i -eq 3 ]] && continue
       [[ $i -eq 5 ]] && break
       echo "$i"
done
```
## Iteration by iteration

i = 1

```shell
   [[ 1 -eq 3 ]] → false → && short-circuits → continue does NOT run
   [[ 1 -eq 5 ]] → false → && short-circuits → break does NOT run
   echo "1"       → prints 1
```

i = 2

```shell
   [[ 2 -eq 3 ]] → false → continue does NOT run
   [[ 2 -eq 5 ]] → false → break does NOT run
   echo "2"       → prints 2
```

i = 3

```shell
   [[ 3 -eq 3 ]] → TRUE → && runs → continue executes
```

`Continue means: stop this iteration right now, jump to the next one.`

The two lines below never run for i=3. Jumps straight to i=4

i = 4

```shell
   [[ 4 -eq 3 ]] → false → continue does NOT run
   [[ 4 -eq 5 ]] → false → break does NOT run
   echo "4"       → prints 4
```

i = 5

```shell
   [[ 5 -eq 3 ]] → false → continue does NOT run
   [[ 5 -eq 5 ]] → TRUE → && runs → break executes
```

`Break means: exit the loop entirely right now.` 
The echo below never runs, and there are no more iterations.

## The pattern here

```shell
[[ $i -eq 3 ]] && continue
```
This only works because of how `&&` behaves — if the left side is false, the
right side never runs. So continue and break only fire when the condition
is actually true. It's a compact way to write:

```shell
   if [[ $i -eq 3 ]]; then
       continue
   fi
```
Same thing, one line.

---

# Practice script 1: Build: Script 1 — Bulk File Creator

```shell
  #!/usr/bin/env bash
  # bulk_create.sh — Create multiple files automatically
  # Usage: ./bulk_create.sh <prefix> <count>

  if [[ $# -ne 2 ]]; then
      echo "Usage: $0 <prefix> <count>" >&2
      exit 1
  fi

  prefix="$1"
  count="$2"

  if [[ ! "$count" =~ ^[0-9]+$ ]]; then
      echo "ERROR: count must be a number" >&2
      exit 1
  fi

  mkdir -p "./output"

  for (( i=1; i<=count; i++ )); do
      filename="./output/${prefix}_${i}.txt"
      echo "Created: $(date '+%Y-%m-%d %H:%M:%S')" > "$filename"
      echo "File: $filename"
  done

  echo "Done. $count file(s) created in ./output/"
```

## Things I learnt

### Breaking down code

```shell
if [[ ! "$count" =~ ^[0-9]+$ ]]; then 
```
In one line this is a regex matcher that checks if the string contains only digits from the starting to the ending.

- `=~` -> indicates a regex
-  `^` -> Start of string
-  `[0-9]` -> Any digit
-  `+` -> One or more
-  `$` -> End of string

#### What happens WITHOUT ^ and $

Suppose regex is only:

```shell
[0-9]+
```
Now Bash checks:

`"Does the string contain digits anywhere?"`

NOT:

`"Is the whole string only digits?"`

---

# Practice script 2 : Process Lister

```shell
  #!/usr/bin/env bash
  # process_lister.sh — Loop through running processes and display them
  # Usage: ./process_lister.sh <username>

  target_user="${1:-$(whoami)}"    # use $1 if given, else current user

  echo "Processes for user: $target_user"
  echo "-----------------------------------"
  echo "PID    CPU%  MEM%  COMMAND"
  echo "-----------------------------------"

  while IFS= read -r line; do
      echo "$line"
  done < <(ps -u "$target_user" -o pid,%cpu,%mem,comm --no-headers
  2>/dev/null)
```

 ## Things I learnt 

 - default value  --> ${var:-default}
This means that `if var is given then use it or use the default value`
 
 - < <(command) — process substitution. It runs the command and feeds its output like a file into the while loop. This keeps you in the current shell (important for variables).

 - ps -u "$target_user" -o pid,%cpu,%mem,comm --no-headers
  2>/dev/null

   ### Breakdown of the code

| Part                    | Meaning                           |
|------------------------ | --------------------------------- |
|   ps                    | Show running processes            |
|  -u "$target_user"      | Show processes owned by that user |
|   -o pid,%cpu,%mem,comm | Custom output columns             |
|   --no-headers          | Remove column headings            |
|   2>/dev/null           | Discard error messages            |


---

# Summary

| Concept              | Syntax                                      |
|----------------------|----------------------------------------------|
| for over list        | `for x in a b c; do ... done`               |
| for with counter     | `for (( i=1; i<=n; i++ )); do`              |
| while condition      | `while [[ condition ]]; do`                 |
| read file line by line | `while IFS= read -r line; do ... done < file` |
| skip iteration       | `continue`                                  |
| exit loop            | `break`                                     |
| default value        | `${var:-default}`                           |
| process substitution | `< <(command)`                              |

---
