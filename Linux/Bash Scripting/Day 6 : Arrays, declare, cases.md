# Arrays

## Creating an array

```shell
fruits=("apple" "banana" "mango")
```
---

## Accessing the elements

```shell
echo "${fruits[0]}" # access the element at index 0 (apple)

echo "${fruits[@]}" # prints all the elements in the array
```
---

## Size of the array

```shell
echo "${#fruits[@]}" 
```
---

## Looping through an array

```shell
for fruit in "${fruits[@]}"; do
    echo "$fruit"
done
```
---

## Adding elements

```shell
fruits+=("orange") # adds the element to the end of the array
fruits+=("kiwi" "mango" "grapes") # adding multiple elements to the end of the array

fruits[2]="orange" # index based insertion
```

### Adding the elements using variables

```shell
new_fruit="pineapple"
fruits+=("$new_fruit")
```

### Appending elements using a loop 

```shell
for item in apple banana orange; do
    fruits+=("$item")
done
```

### Concatenation of arrays

```shell
arr1=("a" "b")
arr2=("c" "d")

arr1+=("${arr2[@]}"

# output : a b c d
```
---

## Removing elements

```shell

unset 'fruits[1]'
fruits+=("new_item")
```
---

# Declare syntax

`declare` is a **Bash built-in command** used to **define variables with specific attributes** like type, scope, or behavior.

Think of it as a **more explicit and production-safe way to create variables**, compared to just doing:

```bash
var=value
```

## Basic Syntax

```bash
declare [options] variable_name=value
```

## 1. Declaring an Array (Most Common Use)

```bash
declare -a fruits=("apple" "banana")
fruits+=("orange")
```

* `-a` → indexed array

***

## 2. Associative Arrays (Key-Value Maps)

```bash
declare -A user

user[name]="Harish"
user[role]="DevOps"
```

* `-A` → associative array (like dictionaries in Python)

***

## 3. Read-Only Variables (Constant)

```bash
declare -r PI=3.14
```

* `-r` → makes variable immutable

```bash
PI=4   # ❌ error
```

***

## 4. Integer Variables

```bash
declare -i count=5
count+=10
echo $count   # 15
```

* `-i` → treats value as integer automatically

***

## 5. Export Variables (Environment Variables)

```bash
declare -x PATH_VAR="value"
```

Same as:

```bash
export PATH_VAR="value"
```

***

## 6. Lowercase / Uppercase Transformation

```bash
declare -l name="HARISH"
echo $name   # harish
```

```bash
declare -u name="harish"
echo $name   # HARISH
```

***

## 7. Print Variables (Debugging)

```bash
declare -p fruits
```

Output example:

```
declare -a fruits=([0]="apple" [1]="banana")
```

***

## Why Use `declare` in Production?

### Clarity

```bash
declare -a servers # → clearly tells this is an array
```

### Type Safety

```bash
declare -i num=10
num="abc"   # becomes 0 instead of breaking logic
```
---

# Quick Cheat Sheet

| Option | Meaning           |
| ------ | ----------------- |
|   -a   | Indexed array     |
|   -A   | Associative array |
|   -i   | Integer           |
|   -r   | Read-only         |
|   -x   | Export variable   |
|   -l   | Lowercase         |
|   -u   | Uppercase         |
|   -p   | Print variable    |

---

# case

```shell
#!/usr/bin/env bash

service_action() {
    local action="$1"

    case "$action" in
        start)
            echo "Starting nginx"
            ;; # stop the current branch and exit ( equivalent to 
        stop)
            echo "Stopping nginx"
            ;;
        status)
            echo "Checking nginx status"
            ;;
        *)
            echo "Usage: $0 {start|stop|status}" >&2
            return 1
            ;;
    esac
}

main() {
    service_action "$1"
}

main "$@"
```
---

# Practice script 1: Service management CLI

```SHELL
#!/usr/bin/env bash

set -euo pipefail

SERVICE_NAME="nginx"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log_info() {
    local message="$1"
    echo "$(timestamp) [INFO] $message"
}

log_warn() {
    local message="$1"
    echo "$(timestamp) [WARN] $message"
}

log_error() {
    local message="$1"
    echo "$(timestamp) [ERROR] $message" >&2
}

start_server() {
    log_info "Starting $SERVICE_NAME service"

    sleep 1

    log_info "$SERVICE_NAME started successfully"
}

stop_server() {
    log_info "Stopping $SERVICE_NAME service"

    sleep 1

    log_info "$SERVICE_NAME stopped successfully"
}

restart_server() {
    log_warn "Restart initiated for $SERVICE_NAME"

    stop_server
    start_server

    log_info "$SERVICE_NAME restart completed"
}

server_status() {
    log_info "Checking $SERVICE_NAME status"

    sleep 1

    log_info "$SERVICE_NAME is ACTIVE"
}

usage() {
    echo "Usage: $0 {start|stop|restart|status}" >&2
}

main() {

    if [[ $# -ne 1 ]]; then
        usage
        exit 1
    fi

    local command="$1"

    case "$command" in
        start)
            start_server
            ;;
        stop)
            stop_server
            ;;
        restart)
            restart_server
            ;;
        status)
            server_status
            ;;
        *)
            log_error "Invalid command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
```
---

# Practice script 2: Array-based health checker

```shell
#!/usr/bin/env bash

set -euo pipefail

servers=("web01" "web02" "api01" "db01")

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log_info() {
    local message="$1"
    echo "$(timestamp) [INFO] $message"
}

log_warn() {
    local message="$1"
    echo "$(timestamp) [WARN] $message"
}

log_error() {
    local message="$1"
    echo "$(timestamp) [ERROR] $message" >&2
}

list_servers() {
    log_info "Listing configured servers"

    for server in "${servers[@]}"; do
        echo "- $server"
    done
}

check_server_health() {
    local server="$1"

    log_info "Checking health for $server"

    sleep 1

    local random_status=$((RANDOM % 2))

    if [[ "$random_status" -eq 0 ]]; then
        log_info "$server is HEALTHY"
    else
        log_warn "$server response time HIGH"
    fi
}

check_all_servers() {

    for server in "${servers[@]}"; do
        check_server_health "$server"
    done
}

usage() {
    echo "Usage: $0 {list|check}" >&2
}

main() {

    if [[ $# -ne 1 ]]; then
        usage
        exit 1
    fi

    local command="$1"

    case "$command" in
        list)
            list_servers
            ;;
        check)
            check_all_servers
            ;;
        *)
            log_error "Invalid command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
```
---

# Pattern 

`${1:-}` ---> Use $1 OR empty string if undefined

---

