awk reads input line by line. Each line is a record. Each word separated by whitespace is a field.

```shell
  line:   "root  x  0  0  root  /root  /bin/bash"
  fields:   $1   $2 $3 $4   $5    $6       $7
```
`$0 = the entire line. $1, $2... = individual fields.`

```shell
echo "harish 25 bangalore" | awk '{print $1}'    # harish
echo "harish 25 bangalore" | awk '{print $3}'    # bangalore
echo "harish 25 bangalore" | awk '{print $0}'    # harish 25 bangalore
```
---

# Basic structure

```shell
 awk 'pattern { action }' file
```

- pattern — which lines to process (optional, if omitted = all lines)
- action — what to do with those lines

```shell
  awk '{ print $1 }' /etc/passwd          # print field 1 of every line
  awk '/root/ { print $0 }' /etc/passwd   # print lines containing "root"
  awk 'NR==1 { print $0 }' /etc/passwd   # print only line 1
```
---

# Built-in variables

NR    # current line number (Number of Records)
NF    # number of fields in current line
FS    # field separator (default: whitespace)
OFS   # output field separator

```shell
awk '{ print NR, $1 }' /etc/passwd       # line number + first field
awk '{ print NF }' file.txt              # how many fields per line
awk 'NR>=2 && NR<=5 { print }' file     # print lines 2 to 5
```
---

# Custom field separator with -F

Default separator is whitespace. Use -F to change it:

`/etc/passwd uses : as separator`

```shell
  awk -F: '{ print $1 }' /etc/passwd          # usernames only
  awk -F: '{ print $1, $6 }' /etc/passwd      # username + home dir
  awk -F, '{ print $2 }' data.csv             # second column of CSV
```
---

# BEGIN and END blocks

```shell
  awk 'BEGIN { print "--- Start ---" }
       { print $1 }
       END { print "--- Done. Lines: " NR }' file
```

- BEGIN runs once before any input is read — use for headers, setup
- END runs once after all input — use for totals, summaries

---

# Conditions inside awk

```shell
awk -F: '$3 >= 1000 { print $1 }' /etc/passwd      # users with UID >= 1000
awk '$5 > 80 { print $1, $5 }' disk.txt            # lines where field 5 > 80
awk '/ERROR/ && /timeout/ { print }' app.log        # lines with both words
```
---

# Aggregation

## sum a column

```shell
awk '{ sum += $3 } END { print "Total:", sum }' data.txt
```

## count matching lines

```shell
awk '/ERROR/ { count++ } END { print "Errors:", count }' app.log
```

## average

```shell
awk '{ sum += $2; count++ } END { print "Avg:", sum/count }' data.txt
```
---
