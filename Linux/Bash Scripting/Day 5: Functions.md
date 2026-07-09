# Basic Syntax

```shell
function_name() {
    echo "$1"
    echo "$2"
}

 # Calling it:
function_name "harish" "devops"
```
---

# Script arguments vs Function arguments

```shell
#!/usr/bin/env bash

echo "Script arg: $1"

test_func() {
    echo "Function arg: $1"
}

test_func "inside-function"

```

Run:

```shell
./test.sh script-value
```

Output:

```python
Script arg: script-value
Function arg: inside-function
```
---

# Local in function variables

They are used to store variables inside a function without modifying the global variable.

## Without Local

```shell
#!/usr/bin/env bash
name="harish"

change_name() {
    name="kumar"
}

change_name

echo "$name"
```

Output:

```python
kumar # Because the function modified the global variable.
```

## With Local

```shell
#!/usr/bin/env bash

name="harish"

change_name() {
    local name="kumar"
    echo "$name"
}

change_name

echo "$name"
```

Output:

```python
kumar # because the local variable exists only inside the function
harish # global variable value not modified
```
---

# Production Structure

```shell
#!/usr/bin/env bash
set -euo pipefail

log_info() {
    echo "[INFO] $1"
}

greet_user() {
    local name="$1"

    log_info "Hello $name"
}

main() {
    greet_user "Harish"
}

main
```
Here, we use main because instead of writing function call for hundered of functions separately instead write them inside main and 
then call main so that we can have a clear entry point.

---

# Forwarding Arguments
Sometimes you want a function to pass ALL received arguments further.

```shell
wrapper() {
    deploy "$@"
}
```
If:

```shell
wrapper prod v2
```
Then:

```shell
deploy "$@"
# becomes:
deploy prod v2
```
---

# Practice Script 1: Disk usage monitor

```shell
#!/usr/bin/env bash
set -euo pipefail

threshold=80

log_info() {
    echo "[INFO] $1"
}

log_warn() {
    echo "[WARN] $1"
}

check_disk() {
    usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

    if [[ "$usage" -ge "$threshold" ]]; then
        log_warn "Disk usage is high: ${usage}%"
        return 1
    fi

    log_info "Disk usage normal: ${usage}%"
}

main() {
    check_disk
}

main
```

## Explanation

- `df` -> Disk Filesystem (It shows how much space is used and available on mounted filesystems.)
- `-h` -> Human readable format
- `/` -> Root filesystem
- `awk` -> Powerful text processing tool. It reads input line by line and splits each line into fields (columns).

For example, given:

```shell
Filesystem      Size Used Avail Use% Mounted on
/dev/sda1        40G  27G   11G  72% /
```

The second line is split like this:

```python
Field	Value
$1	/dev/sda1
$2	40G
$3	27G
$4	11G
$5	72%
$6	/
```

- `NR` -> Number of Record (the current line number)
- `tr` -> translate (or transform)
- `-d` -> delete characters

`tr -d '%'` -> Delete every % character.

---

# Practice script 2: Production Logger Utility

```shell
#!/usr/bin/env bash
set -euo pipefail

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log_info() {
    echo "$(timestamp) [INFO] $1"
}

log_warn() {
    echo "$(timestamp) [WARN] $1"
}

log_error() {
    echo "$(timestamp) [ERROR] $1" >&2
}

main() {
    log_info "Application started"
    log_warn "Disk nearing threshold"
    log_error "Database connection failed"
}

main
```

---
