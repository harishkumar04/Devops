# Variables

```shell
name="harish"age=25
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

# Posistional Arguments

```shell
# Let's say I call ./script.sh devops aws:

$0    # script name itself: ./script.sh
$1    # first argument:     devops
$2    # second argument:    aws
$#    # number of arguments: 2
$@    # all arguments:      devops aws
$*    # all arguments as single string (avoid this, use $@)

echo "Script: $0"
echo "First arg: $1"
echo "All args: $@"
echo "Arg count: $#"
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

```
