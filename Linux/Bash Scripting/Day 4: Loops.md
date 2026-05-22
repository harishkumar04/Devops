# 1. for Loop

## Loop over a list

```shell
for item in one two three; do
    echo "$item"
done
```
## Loop over files

```shell
for file in /var/log/*.log; do
      echo "Found: $file"
done
```

## C-style loop (when you need a counter)

```shell
  for (( i=1; i<=5; i++ )); do
      echo "Number: $i"
  done
```
## Loop over arguments

```shell
  for arg in "$@"; do
      echo "$arg"
  done
```


 Runs as long as the condition is true:

  count=1
  while [[ $count -le 5 ]]; do
      echo "Count: $count"
      count=$((count + 1))
  done
