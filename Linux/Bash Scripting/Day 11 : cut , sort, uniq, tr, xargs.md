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

remove/count adjacent duplicates (always sort first!)

```shell
   sort file.txt | uniq             # remove duplicates
   sort file.txt | uniq -c          # count occurrences
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
