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
