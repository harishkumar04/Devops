# 1. if / else Syntax

```shell
   if [[ condition ]]; then
       # runs if condition is true
   elif [[ condition ]]; then
       # runs if first was false, this is true
   else
       # runs if all above were false
   fi
```

The spaces inside `[[ ]]` are required. `[[condition]]` will fail.

---

# 2. String Comparisons

```shell
   name="harish"

   [[ "$name" == "harish" ]]    # equal
   [[ "$name" != "admin" ]]     # not equal
   [[ -z "$name" ]]             # true if string is EMPTY
   [[ -n "$name" ]]             # true if string is NOT empty
```

Always quote variables inside conditions

---

# 3. Number comparisons

```shell
x=10
   
[[ $x -eq 10 ]]    # equal
[[ $x -ne 5 ]]     # not equal
[[ $x -gt 5 ]]     # greater than
[[ $x -lt 20 ]]    # less than
[[ $x -ge 10 ]]    # greater than or equal
[[ $x -le 10 ]]    # less than or equal
```

---

# 4. File Tests — the most used ones in production

```shell
[[ -e "$file" ]]    # exists (file or directory)
[[ -f "$file" ]]    # exists and is a regular file
[[ -d "$path" ]]    # exists and is a directory
[[ -r "$file" ]]    # readable
[[ -w "$file" ]]    # writable
[[ -x "$file" ]]    # executable
[[ -s "$file" ]]    # exists and is NOT empty (size > 0)
```
These are used constantly — checking config files exist before reading them, checking log directories exist before writing, etc.

---

# 5. Combining Conditions

```shell
[[ condition1 && condition2 ]]    # AND — both must be true
[[ condition1 || condition2 ]]    # OR  — at least one must be true
[[ ! condition ]]                 # NOT — inverts the result
```

---

# Practice Script 1: File valiadator

file_validator.sh — Validate a file's existence and permissions
Usage: ./file_validator.sh <filepath>

```shell
   #!/usr/bin/env bash

   if [[ $# -eq 0 ]]; then
       echo "Usage: $0 <filepath>" >&2
       exit 1
   fi

   file="$1"

   if [[ ! -e "$file" ]]; then
       echo "ERROR: '$file' does not exist" >&2
       exit 1
   fi

   if [[ -f "$file" ]]; then
       echo "Type      : regular file"
   elif [[ -d "$file" ]]; then
       echo "Type      : directory"
   fi

   [[ -r "$file" ]] && echo "Readable  : yes" || echo "Readable  : no"

   # && runs the right side only if left side succeeded (exit 0)
   # || runs the right side only if left side failed (non-zero)

   [[ -w "$file" ]] && echo "Writable  : yes" || echo "Writable  : no"
   [[ -x "$file" ]] && echo "Executable: yes" || echo "Executable: no"
```

# Practice Script 2: Login Simulation

login_sim.sh — Simulate a login with username/password validation

```shell
#!/usr/bin/env bash

VALID_USER="admin"
VALID_PASS="PASSWORD123"
MAX_ATTEMPTS=3
attempts=0

while [[ $attempts -lt $MAX_ATTEMPTS ]]; do
  read -p "Username: " username
  read -s -p "Password: " password
  echo ""

  if [[ "$username" == "$VALID_USER" && "$password" == "$VALID_PASS" ]]; then
    echo "Login successful. Welcome, $username"
    exit 0
  fi

  attempts=$((attempts + 1))
  remaining_attempts=$((MAX_ATTEMPTS - attempts))

  if [[ $remaining -gt 0 ]]; then
    echo "Invalid Credentials! $remaining attempt(s) remaining."
  fi
done

echo "Too many failed attempts.. Acess Denied!" >&2
exit 1
```

--- 

# Production Pattern

```shell
if grep -q "error" app.log; then
       echo "errors found"
fi
```

-q (quiet mode), grep does only one thing:
   1. Searches for the pattern
   2. Prints nothing — but still sets the exit code

The exit code is what matters

```python
   found a match    →  exit code 0  (success)
   found no match   →  exit code 1  (failure)
```

`if` in Bash works purely on exit codes:

   - exit code 0 → condition is true → runs the then block
   - non-zero → condition is false → skips it
