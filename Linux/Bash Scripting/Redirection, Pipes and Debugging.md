# Redirection

## Streams

| Stream | Number | Purpose       |
| ------ | ------ | ------------- |
| stdin  | 0      | Input         |
| stdout | 1      | Normal output |
| stderr | 2      | Errors        |

```shell
echo "Hello" > output.txt # creates the file and then adds "Hello"

# append
echo "Hello" >> output.txt # first this gets added
echo "World" >> output.txt # this gets added in the next line below "Hello"

ls missingfile 2> error.log # stores errors
ls missingfile 2>> error.log # appends into errors

ls existing.txt missing.txt > output.log 2>&1
# meaning
# 1 -> output.log
# 2 -> same place as 1

# Correct way
command > file.log 2>&1

# Wrong way
command 2>&1 > file.log # Because order matters... Bash processes left to right.
```
---

# Pipes

A pipe takes stdout from one command and sends it as stdin to another.

```shell
ps aux | grep nginx # finding nginx
```
---

# tee

The problem with the redirection is that the output is stored in that file and we can't see it in our terminal so if you want to see the errors and
outputs in the screen and then also store it in the file, that is when we use tee.

```shell
echo "Hello" > app.log # Stores in file but doesn't show on terminal.
```

Use:

```shell
echo "Hello" | tee app.log # shown in the output as well as stored in the app.log

echo "World" | tee -a app.log # Append mode
```

# Production usage:

```shell
./deploy.sh | tee deploy.log # Watch deployment live and Save deployment log at the same time
```
---

# Debugging

Shows every executed command.

## Method 1

```shell
bash -x script.sh

# Output:
+ VAR=test
+ echo test
```
## Method 2

```shell
# Inside script:
set -x
```

Example:

```shell
#!/usr/bin/env bash

set -x

name="harish"

echo "$name"
Disable:
set +x
Example:
set -x

echo "debug"

set +x

echo "normal"
```
---

# Practice Script 1: Log writer

```shell
#!/usr/bin/env bash

set -euo pipefail
LOG_FILE="system.log"
echo "===== $(date) =====" | tee -a "$LOG_FILE"
df -h | tee -a "$LOG_FILE"
free -h | tee -a "$LOG_FILE"
uptime | tee -a "$LOG_FILE"
echo "Log written successfully."
```
---

# Practice Script 2: Error Logger

```shell
#!/usr/bin/env bash

set -euo pipefail

STDOUT_LOG="stdout.log"
STDERR_LOG="stderr.log"

echo "Checking files..." > "$STDOUT_LOG"

ls /etc >> "$STDOUT_LOG" 2>> "$STDERR_LOG"

ls /not_exist >> "$STDOUT_LOG" 2>> "$STDERR_LOG"

echo "Finished." >> "$STDOUT_LOG"
```
---
