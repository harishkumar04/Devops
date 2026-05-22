# Shell vs Bash
Shell is a generic term — it's any program that takes your commands and passes them to the OS kernel. There are many shells: sh, zsh, fish, ksh.

Bash (Bourne Again SHell) is the most common shell in Linux production environments. When you write automation scripts for servers, CI/CD pipelines, or SRE tooling — you're
almost always writing Bash.

```shell
   echo $SHELL        # what shell you're currently using
   cat /etc/shells    # all shells installed on the system
   bash --version     # bash version (production servers often run 4.x or 5.x)
```
---

# Command substitution

```shell
$() # Command substitution — modern, nestable
$(date)
```
---

# The Shebang #!/bin/bash

The very first line of every Bash script must be:

```shell
   #!/bin/bash
```
This tells the OS: "use /bin/bash to execute this file." Without it, the system may use a different shell (sh, dash, etc.) which behaves differently and will break your
scripts in subtle ways.
   
Why this matters in production: Servers often have sh pointing to dash, not bash. Missing the shebang = unexpected failures.

```shell
   which bash          # find where bash lives on your system
   # common locations: /bin/bash or /usr/bin/bash
```

If you're unsure, use the portable form:

```shell
   #!/usr/bin/env bash  # finds bash from PATH — safer across systems
```
--- 

# Streams

Every process has 3 standard streams:

| Stream | Number | Purpose       |
|--------|--------|---------------|
| stdin  | 0      | Input         |
| stdout | 1      | Normal output |
| stderr | 2      | Error output  |

```shell
echo "this goes to stdout"
echo "this is an error" >&2    # redirect to stderr
```
In the above command `>&2` meanst redirect the stdout to whereever the stderr is pointing. This is done because by default echo gives `stdout` and both the `stdout and stderr are printed on the terminal` which makes it difficult to identify which is error and output.

The moment you write an error message, you should automatically type >&2. Not because you need it right now — because the script will eventually be used in a context where it matters, and retrofitting it later is how bugs happen.

## Example 1

```shell
./demo.sh > output.log 2> error.log
```

- > redirects stdout to output.log
- 2> redirects stderr to error.log
- Terminal shows nothing — both are captured to
   files

We can view them by

```shell
   cat output.log    # only normal output
   cat error.log     # only error messages
```

## Example 2

```shell
./script.sh > output.log 2>&1

```
Reading left to right:

1. > output.log — point stdout (fd 1) to output.log
2. 2>&1 — point stderr (fd 2) to wherever fd 1 is pointing — which is now output.log

Result: both stdout and stderr go to output.log.

## Order matters:

```shell
./script.sh 2>&1 > output.log    # WRONG — stderr still goes to terminal

./script.sh > output.log 2>&1    # CORRECT — both go to file
```

## Common patterns

```shell
# only capture stdout, errors still show on terminal
./demo.sh > output.log
# or
./demo.sh 1> output.log # both are same

# only capture stderr, normal output still shows on terminal
./demo.sh 2> error.log

# capture both to the same file
./demo.sh > all.log 2>&1

# capture both to separate files
./demo.sh > output.log 2> error.log

# discard errors completely, only see stdout
./demo.sh 2> /dev/null

# /dev/null is a black hole — anything redirected there is gone
```

---

# bash -x (trace mode)

It prints every command before executing it.

```shell
bash -x sysinfo.sh
```
Output looks like:

```shell
+ echo 'User     : harish'
User     : harish

+ echo 'Hostname : macbook'
Hostname : macbook
```

**The + prefix shows the expanded command that actually ran. This lets you see exactly what Bash is doing, line by line.**

---

# set -x inside the script

You can enable trace mode from within the script itself:

```shell
   #!/bin/bash
   set -x          # enable trace from this point
   echo "hello"
   set +x          # disable trace
   echo "this won't be traced"
```

Useful when you only want to trace a specific section of a large script.

---

# set -e —> exit on error

```shell
   #!/bin/bash
   set -e          # script exits immediately if any command fails
```

Without set -e, a script will keep running even after a command fails — silently producing wrong results. In production, you almost always want set -e.

---

# set -euo pipefail

```shell
#!/usr/bin/env bash
   set -euo pipefail
```

- set -e — exit on error
- set -u — exit if you use an undefined variable
- set -o pipefail — catch failures inside pipes (e.g., cmd1 | cmd2 — without this, only cmd2's exit code is checked)
