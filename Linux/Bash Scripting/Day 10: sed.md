# What is sed
sed = stream editor. 

- It reads input line by line, applies transformations, and outputs the result. 
- Unlike awk (which is for data extraction), sed is primarily for text modification — find and replace, delete lines, insert text.

# Structure

```shell
sed 'command' file
```

# Example file for the practice

```shell
cat > server.log << 'EOF'
   Server starting on host=localhost
   port=8080 is now open
   ERROR: connection failed on port=8080
   debug mode is debug=false
   WARNING: retrying connection to port=8080

   ERROR: timeout after 30s
   Server ready on localhost
   EOF
```


   1. Substitution s/old/new/g

   # replace first occurrence per line only
   sed 's/port=8080/port=9090/' server.log
   # line 2: "port=9090 is now open"
   # line 3: "ERROR: connection failed on port=9090"  ← only first match changed

   # replace ALL occurrences per line
   sed 's/port=8080/port=9090/g' server.log
   # line 3 had port=8080 once, so same result here
   # but if a line had port=8080 twice, /g catches both

   # case insensitive
   sed 's/error/ALERT/gi' server.log
   # "ERROR: connection failed..." → "ALERT: connection failed..."
   # "ERROR: timeout..."          → "ALERT: timeout..."

   None of these touch the actual file — output goes to terminal only.

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   2. Inline editing -i and -i.bak

   # modify file in place — original is gone
   sed -i 's/localhost/prodserver01/g' server.log
   cat server.log
   # "Server starting on host=prodserver01"
   # "Server ready on prodserver01"

   # modify file but save original as server.log.bak
   sed -i.bak 's/localhost/prodserver01/g' server.log
   cat server.log      # modified version
   cat server.log.bak  # original preserved

   Always use -i.bak in production. If your regex was wrong you can restore:

   cp server.log.bak server.log    # undo

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   3. Deleting lines

   # delete lines containing ERROR
   sed '/ERROR/d' server.log
   # Output — ERROR lines are gone:
   # Server starting on host=localhost
   # port=8080 is now open
   # debug mode is debug=false
   # WARNING: retrying connection to port=8080
   #
   # Server ready on localhost

   # delete empty lines (^ = line start, $ = line end, nothing between = empty)
   sed '/^$/d' server.log
   # the blank line between WARNING and ERROR disappears

   # chain both — delete ERROR lines AND empty lines
   sed -e '/ERROR/d' -e '/^$/d' server.log
   # Server starting on host=localhost
   # port=8080 is now open
   # debug mode is debug=false
   # WARNING: retrying connection to port=8080
   # Server ready on localhost

   # delete specific line numbers
   sed '3d' server.log          # delete line 3
   sed '3,5d' server.log        # delete lines 3 through 5

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   4. Printing specific lines with -n

   Without -n, sed prints every line. -n suppresses that — only explicit p commands produce output.

   # print only line 3
   sed -n '3p' server.log
   # ERROR: connection failed on port=8080

   # print lines 2 to 4
   sed -n '2,4p' server.log
   # port=8080 is now open
   # ERROR: connection failed on port=8080
   # debug mode is debug=false

   # print only lines matching a pattern
   sed -n '/ERROR/p' server.log
   # ERROR: connection failed on port=8080
   # ERROR: timeout after 30s

   # print lines between two patterns (inclusive)
   sed -n '/WARNING/,/ERROR/p' server.log
   # WARNING: retrying connection to port=8080
   #                                            ← empty line included
   # ERROR: timeout after 30s

   This last one is extremely useful in production — extracting a section of a log between two markers.
