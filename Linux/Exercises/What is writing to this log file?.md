# Description: 
A developer created a testing program that is continuously writing to a log file `/var/log/bad.log` and filling up disk. You can check for example with tail -f /var/log/bad.log.
This program is no longer needed. Find it and terminate it. Do not delete the log file.

---

# Solution

## Step 1: Watch the Logs first

```bash
tail -f /var/log/bad.log
```

- `tail` -> prints the end of the file
- `f` -> follow

## Step 2: Find which process has the file open

```bash
sudo lsof /var/log/bad.log
```
- `lsof` -> List Open Files

In Linux, everything is treated as a file, including:
```python
regular files
directories
disks
sockets
pipes
```

If a program is writing to a file, it must have that file open.

Example output:
```python
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
logger   2413 root    3w   REG  8,1    24567   ... /var/log/bad.log
```

Here, FD is the important thing 

### File Descriptor

A File Descriptor (FD) is simply a number that a process uses to refer to an open file or other I/O resource.

When a program opens a file, Linux doesn't keep using the file's pathname internally. Instead, the kernel returns a small integer called a file descriptor, and the program uses that number for subsequent reads and writes.
Think of it like this:

```python
The filename (/var/log/bad.log) is the address.
The file descriptor (3) is the ticket number the program receives after opening it.
The program writes using the descriptor, not by repeatedly looking up the filename.
```

#### Why does the next file become FD 3?

Suppose a program starts and then opens /var/log/bad.log:

```python
int fd = open("/var/log/bad.log", O_WRONLY);
```

The kernel looks for the lowest unused file descriptor.

```python
Since 0, 1, and 2 are already taken, it returns:
3
```

Now the program writes using FD 3.

- If it opens another file: -> 4
- Another: 5
and so on.

The FD column has two parts:

```python
3 → the file descriptor number
w → the access mode
```

## Step 3: Check using the ps processes

```python
ps -fp 2413
```

## Step 4: Stop the process

Once you know the PID:

```python
sudo kill 2413
```
