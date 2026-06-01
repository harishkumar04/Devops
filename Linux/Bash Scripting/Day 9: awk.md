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
