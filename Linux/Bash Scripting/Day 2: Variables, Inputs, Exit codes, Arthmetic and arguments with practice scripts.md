# Variables

```shell
name="harish"
age=25
echo $name        # access with $
echo ${name}      # safer form — use this when concatenating
echo "$name"      # Best way -> always quote variables 

# Only use the ${} when you need to do string concatenation like show below

echo "$name_backup"    # Bash looks for variablenamed 'name_backup' — empty
echo "${name}_backup"  # correct — appendsb'_backup' to value of name

current_user=$(whoami)

```
---

```shell

echo "User: $current_user, Date: $today"
echo "User: ${current_user}, Date: ${today}"  # -> Best way

# Both produce identical output.
# In production scripts, they use "${var}" everywhere — that's just people being maximally explicit. It's not wrong, just slightly verbose.
# Both "$var" and "${var}" are correct and safe when quoted.
```
---

# read — Interactive Input

```shell
read name                    # waits for user to type, stores in $name
read -p "Enter name: " name  # -p shows a prompt on the same line
read -s -p "Password: " pass # -s = silent (no echo, for passwords)
read -t 10 -p "Input: " val  # -t = timeout in seconds
```
---

# Arguments

```shell
# Let's say I call ./script.sh devops aws:

$0    # script name itself: ./script.sh
$1    # first argument:     devops
$2    # second argument:    aws
$#    # number of arguments: 2
$@    # all arguments:      devops aws
$*    # all arguments as single string (avoid this, use $@)
$?    # exit code status like 0(success), 1(Failure) etc

echo "Script: $0"
echo "First arg: $1"
echo "All args: $@"
echo "Arg count: $#"
```

---

# Exit codes

exit terminates the script immediately. The number you pass is the exit code — a signal to whoever ran the script telling them whether it succeeded or failed.

```shell
0  # success
1  # general error (something went wrong)
2  # misuse / wrong arguments (this is actually the more correct code for bad usage)
```

So if someone uses exit 1 inside the if, then the script is saying: "Error occured, I can't continue, I am stopping and reporting failure"

If we don't exit 1 on failure and just let the script continue or exit naturally with 0, the caller thinks everything was fine.

---

# Basic Arthmetic

```shell
x=5
y=3
echo $x + $y        # prints "5 + 3" — string concatenation, not math!
echo $((x + y))     # prints 8 — correct arithmetic
result=$((x * y))
echo $result        # 15
```
---

# Practice Script 1 : User Profile Generator

```shell
#!/usr/bin/env bash
read -p "Enter username: " username
read -p "Enter city: " city

echo "============="
echo "User Profile"
echo "============="
echo " Username: $username"
echo " City : $city"
echo " Date generated: $(date '+%Y-%m-%d %H:%M:%S')"
```

```shell
chmod +x user_profile.sh
./user_profile.sh
```
---

# Practice Script 2 : Argument Parser

```shell
if [[ $# -eq 0 ]]; then
       echo "Usage: $0 <arg1> <arg2> ..." >&2
       exit 1
   fi

echo "Total arguments : $#"
echo "All arguments   : $@"
echo ""

count=1
for arg in "$@"; do
    echo "  Arg $count: $arg"
    count=$((count + 1))
done
```

```shell
chmod +x arg_parser.sh
./arg_parser.sh devops aws bangalore
./arg_parser.sh
```

---

# Advanced Command

```shell
disk_usage=$(df -h / | awk 'NR==2 {print $5}')
echo "Disk used: $disk_usage"
```

## Breakdown

- df -> used to see the disk space
- h -> gives it human readable format like GB/MB
- / -> Check the root filesystem
- | -> takes the output from left side and passes it on to the right side

When you run the  df -h /

Output looks like:
   
   ```shell
   Filesystem      Size  Used Avail Use% Mounted on
   /dev/sda1        50G   20G   28G  42% /
   ```
Two lines — a header and the data line.

- awk processes text line by line, column by column.

- NR = current line number (NR==2 means "only process line 2" — the data line, skip the header)
- $5 = fifth column = Use% = 42%

So awk 'NR==2 {print $5}' extracts just 42% from that output.
