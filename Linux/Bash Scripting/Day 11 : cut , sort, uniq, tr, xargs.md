 First, created this test data :

```shell
# ip_list.txt
cat > ip_list.txt <<EOF
192.168.1.10
10.0.0.5
172.16.0.1
192.168.1.10
10.0.0.5
10.0.0.5
203.0.113.7
192.168.1.10
172.16.0.1
203.0.113.7
EOF

# users.txt — fake /etc/passwd style
cat > users.txt <<EOF
root:x:0:0:Root User:/root:/bin/bash
daemon:x:1:1:Daemon:/usr/sbin:/bin/sh
harish:x:1001:1001:Harish Kumar:/home/harish:/bin/bash
deploy:x:1002:1002:Deploy Bot:/home/deploy:/bin/sh
mysql:x:999:999:MySQL:/var/lib/mysql:/bin/false
EOF
```
---

# cut

`Extract columns from text`

```shell
cut -d: -f1 useres.txt          # field 1, delimiter = :

# output:
root
daemon
harish
deploy
mysql


cut -d, -f2,4 users.txt           # fields 2 and 4

# output:
root:0
daemon:1
harish:1001
deploy:1002
mysql:999

cut -c1-10 users.txt              # characters 1 to 10 from each line
# The -c flag works on character positions, not fields/delimiters.

cut -c1-5   # chars 1 to 5
cut -c5-    # char 5 to end of line
cut -c1     # just the first character
cut -c1,5   # char 1 AND char 5 only
```

Key flags: -d (delimiter), -f (field number), -c (character position)

---

# sort 

`sort lines`

```shell
sort file.txt                    # alphabetical
sort -n file.txt                 # numeric sort
sort -rn file.txt                # reverse numeric
sort -k2 -t: file.txt            # sort by field 2, delimiter :
sort -u file.txt                 # sort + remove duplicates
```
---

# uniq 

uniq only collapses adjacent identical lines — that's why sort comes first.

```shell
   sort file.txt | uniq             # remove duplicates (same as sort -u)
   sort file.txt | uniq -c          # count occurrences of each item
   sort file.txt | uniq -d          # show only duplicates 
   sort file.txt | uniq -u          # show only unique lines
   sort file.txt | uniq -c | sort -rn   # frequency ranking (most common first)
```
uniq only removes adjacent duplicates — always pipe sort before it.

---

# tr 

translate/delete characters

```shell
echo "Hello World" | tr 'a-z' 'A-Z'    # lowercase to uppercase
echo "Hello World" | tr 'A-Z' 'a-z'    # uppercase to lowercase
echo "a:b:c" | tr ':' ','              # replace : with ,
echo "hello   world" | tr -s ' '       # squeeze multiple spaces into one
echo "hello123" | tr -d '0-9'          # delete digits
cat file.txt | tr -d '\r'              # remove Windows carriage returns (CRLF → LF)
```
Key flags: -d (delete), -s (squeeze repeated chars)

---

# xargs 

turn stdin into arguments

The problem xargs solves:

```shell
   # This FAILS — rm doesn't read from stdin
   cat ip_list.txt | rm

   # This works — xargs converts stdin lines into
   arguments
   echo "file1.txt file2.txt" | xargs rm

   # Create 3 test files, then delete them with xargs
   touch /tmp/test1.log /tmp/test2.log /tmp/test3.log
   ls /tmp/test*.log | xargs rm
   ls /tmp/test*.log    # gone

   # -I{} — placeholder, lets you control where the
   argument goes
   cat users.txt | cut -d: -f1 | xargs -I{} echo "Found
   user: {}"

   Found user: root
   Found user: daemon
   Found user: harish
   Found user: deploy
   Found user: mysql

   # -n2 — pass 2 args at a time
   echo "a b c d" | xargs -n2 echo

   a b
   c d

   # Safe version for filenames with spaces (-print0 /
   -0)
   find /tmp -name "*.log" -print0 | xargs -0 rm
```

## Examples

```shell
# without xargs — this FAILS:
find . -name "*.log" | rm          # rm doesn't read from stdin

# with xargs — correct:
find . -name "*.log" | xargs rm

# -I{} — use placeholder for position control
find . -name "*.log" | xargs -I{} mv {} /tmp/old_logs/

# -n1 — pass one argument at a time
cat servers.txt | xargs -I{} ssh {} uptime

# print0 / -0 — safe for filenames with spaces
find . -name "*.log" -print0 | xargs -0 rm
```
Always use -print0 | xargs -0 when filenames might have spaces.

---

# Practice Script 1:  Duplicate IP Detector

```shell
#!/usr/bin/env bash
set -euo pipefail

FILE="${1:?Usage: $0 <ip_file>}"

echo "=== IPs appearing more than once ==="
sort "$FILE" | uniq -d

echo ""
echo "=== Full frequency report ==="
sort "$FILE" | uniq -c | sort -rn | awk '{printf "
%dx  %s\n", $1, $2}'
```

```shell
bash ip_duplicates.sh ip_list.txt
```

```shell
# output
=== IPs appearing more than once ===
10.0.0.5
172.16.0.1
192.168.1.10
203.0.113.7

=== Full frequency report ===
 3x  192.168.1.10
 3x  10.0.0.5
 2x  203.0.113.7
 2x  172.16.0.1
```
---

# Practice Script 2 — Username Extractor

```shell
#!/usr/bin/env bash
set -euo pipefail

FILE="${1:-/etc/passwd}"

echo "=== All usernames ==="
cut -d: -f1 "$FILE" | sort

echo ""
echo "=== Human users (UID >= 1000) ==="
awk -F: '$3 >= 1000 { print $1 }' "$FILE" | sort

echo ""
echo "=== Usernames uppercased ==="
cut -d: -f1 "$FILE" | tr 'a-z' 'A-Z' | sort
```

```shell
bash username_extractor.sh users.txt
```

```shell
#Output

=== All usernames ===
daemon
deploy
harish
mysql
root

=== Human users (UID >= 1000) ===
deploy
harish

=== Usernames uppercased ===
DAEMON
DEPLOY
HARISH
MYSQL
ROOT
```
---

# Example that ties it all together

```shell
# "Give me the top 3 most frequent IPs from the log"
sort ip_list.txt | uniq -c | sort -rn | head -3 |
awk '{print $2}'

192.168.1.10
10.0.0.5
203.0.113.7

# "Extract all usernames, clean to uppercase, one per line"
cut -d: -f1 users.txt | tr 'a-z' 'A-Z' | sort | uniq

# "Delete log files older than 7 days"
find /var/log -name "*.log" -mtime +7 | xargs rm
```
