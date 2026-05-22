# 1. if/else Syntax

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

# Practice Script 2: Login Simulation

```shell
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

