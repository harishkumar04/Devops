Given a web server access log where each line begins with a client's IP address, identify the IP that generated the highest number of requests. Extract the first column, count the occurrences of each IP, determine the most frequent one (with no ties), and write the result to /home/admin/highestip.txt. The solution can be verified by ensuring the IP appears 482 times in the log and that the SHA1 checksum of the output file matches the expected value.

# Solution

```python
awk '{print $1}' /home/admin/access.log \
| sort \
| uniq -c \
| sort -nr \
| head -n1 \
| awk '{print $2}' \
> /home/admin/highestip.txt
```

## How it works
- `awk '{print $1}'` – Extracts the first column (IP address).
- `sort` – Groups identical IPs together.
- `uniq -c` – Counts how many times each IP appears. (It creates two columns First column = count and the Second column = IP address)
- `sort -nr` – Sorts by count in descending order. (`n` → numeric sort and `-r` → reverse order (largest first))
- `head -n1` – Selects the IP with the highest count.
- `awk '{print $2}'` – Extracts only the IP address. (Keeps only the first line)
- `>` – Writes the result to `/home/admin/highestip.txt`.

# Verify

```python
grep -c -F -f /home/admin/highestip.txt /home/admin/access.log
```
## Explanation

| Part               | Purpose                                                         |
| ------------------ | --------------------------------------------------------------- |
| `grep`             | Searches text in a file                                         |
| `-c`               | Prints only the count of matching lines                         |
| `-F`               | Treats the pattern as a literal string (ideal for IP addresses) |
| `-f highestip.txt` | Reads the search pattern (IP address) from `highestip.txt`      |
| `access.log`       | The file being searched                                         |
