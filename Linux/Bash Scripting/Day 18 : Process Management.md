# What is a Process?

Every running program in Linux is a process. Each process gets:

- A PID (Process ID) — unique number
- A PPID (Parent PID) — who spawned it
- A state — Running, Sleeping, Zombie, Stopped
- CPU/Memory usage stats

# Core commands

`ps — Process Snapshot`

```bash
ps aux                    # all processes, all users, with details
ps aux --sort=-%cpu       # sorted by CPU (highest first)
ps aux --sort=-%mem       # sorted by memory (highest first)
ps -ef                    # full format, shows PPID
ps -p 1234                # info about specific PID
ps -u harish              # processes owned by a user
```

## What each column means in ps aux:

```bash
USER   PID  %CPU  %MEM    VSZ   RSS TTY  STAT  START   TIME  COMMAND
root     1   0.0   0.1  168304  9876 ?   Ss   May01   0:01  /sbin/init
```
- VSZ — virtual memory size (includes swapped out memory)
- RSS — actual physical RAM used
- STAT — process state:
    - R = Running
    - S = Sleeping (interruptible)
    - D = Uninterruptible sleep (disk I/O)
    - Z = Zombie (finished but not cleaned up)
    - T = Stopped
    - s = session leader
    - < = high priority
    - l = multi-threaded

## top / htop

```bash
top                       # live updating process list
top -bn1                  # non-interactive, 1 batch snapshot (useful in scripts)
top -bn1 | head -20       # top 20 lines of one snapshot
```

`bn1 is the key for scripts:`
   - -b = batch mode (no interactive, just prints and exits)
   - -n1 = run only 1 iteration

## pgrep / pkill — Find/Kill by Name

```bash
pgrep nginx               # find PIDs of processes named nginx
pgrep -l nginx            # PID + name
pgrep -u harish           # all processes by user
pkill nginx               # kill all nginx processes by name
pkill -9 nginx            # force kill (SIGKILL)
pkill -u harish           # kill all processes by a user
```

## kill — Send Signals

```bash
kill 1234                 # send SIGTERM (15) — graceful shutdown request
kill -9 1234              # send SIGKILL — force kill, no cleanup
kill -HUP 1234            # send SIGHUP — reload config (nginx uses this)
kill -l                   # list all signals
```

### Common signals:

| Signal | Number | Meaning |
| --- | --- | --- |
| SIGTERM | 15 | Please stop gracefully |
| SIGKILL | 9 | Stop NOW, no cleanup |
| SIGHUP | 1 | Reload config |
| SIGINT | 2 | Ctrl+C |
| SIGSTOP | 19 | Pause process |
| SIGCONT | 18 | Resume paused process |

`Rule`: Always try SIGTERM first. Only use SIGKILL if SIGTERM doesn't work after a few seconds.

## lsof — What Files/Ports a Process Has Open

```bash
lsof -i :8080             # what process is using port 8080?
lsof -p 1234              # all files open by PID 1234
lsof -u harish            # all files open by user harish
lsof +D /var/log          # all processes with files open in a directory
```
---

# The Kill Signals (Deep dive)

## SIGTERM (15) 

— "Please stop"

```bash
kill 1234
kill -15 1234
kill -TERM 1234
```

- Sends a polite request to stop
- Process can catch this signal and handle it — close files, flush buffers, cleanup temp files, finish current request
- Process can even ignore it (bad practice but possible)
- This is what systemctl stop sends first
- Always try this first

## SIGKILL (9) 

— "Stop NOW, no choice"

```bash
kill -9 1234
kill -KILL 1234
```

- Cannot be caught, blocked, or ignored — kernel enforces it directly
- Process gets no chance to clean up — files may be left open, transactions incomplete, temp files not deleted
- Use only when SIGTERM fails after waiting a few seconds
- Never use as first choice — data corruption risk

## SIGHUP (1) — "Your terminal closed" / "Reload config"

```
kill -1 1234
kill -HUP 1234
kill -HUP $(pgrep nginx)   # reload nginx config, zero downtime
```
- Originally meant: the terminal the process was attached to disconnected
- Most daemons (nginx, apache, sshd) repurpose this to mean "reload your config file" without restarting
- Much faster than restart — no downtime

## SIGINT (2) 

— "Ctrl+C"

```bash
kill -2 1234
kill -INT 1234
```
- Same signal your terminal sends when you press Ctrl+C
- Process can catch and handle it gracefully
- Difference from SIGTERM: SIGINT is "user interrupted", SIGTERM is "system asking to stop"

## SIGSTOP (19) / SIGCONT (18) — Pause/Resume

```bash
kill -STOP 1234   # pause the process (frozen, still in memory)
kill -CONT 1234   # resume it
```
- SIGSTOP cannot be caught or ignored (like SIGKILL)
- Process is suspended — uses no CPU but stays in RAM
- Useful for debugging, or temporarily pausing a heavy process
- Ctrl+Z in terminal sends SIGTSTP (20) — similar but catchable

## SIGQUIT (3) — "Quit and dump core"

```bash
kill -3 1234
kill -QUIT 1234
# or Ctrl+\ in terminal
```
- Like SIGINT but also produces a core dump (memory snapshot for debugging)
- Useful when a process is hung and you want to see what it was doing

## SIGUSR1 / SIGUSR2 (10, 12) — "Application-defined"

```bash
kill -USR1 1234
kill -USR2 1234
```
- No built-in meaning — each application defines what to do
- nginx: SIGUSR1 = reopen log files (used after log rotation)
- Apache: SIGUSR1 = graceful restart

---
# Signal Decision Flow

```bash
   Process not responding?
           │
           ▼
      kill -15 PID        ← try SIGTERM first
      sleep 5             ← wait 5 seconds
           │
           ▼
      Is it still running?
      ├── NO  → Done ✅
      └── YES → kill -9 PID   ← only now use SIGKILL
```
In a script:

```shell
  graceful_kill() {
       local pid="$1"

       kill -15 "$pid" 2>/dev/null

       # Wait up to 10 seconds for graceful stop
       for i in {1..10}; do
           sleep 1
           if ! kill -0 "$pid" 2>/dev/null; then
               echo "Process $pid stopped gracefully"
               return 0
           fi
       done

       # Force kill if still alive
       echo "Force killing $pid" >&2
       kill -9 "$pid" 2>/dev/null
   }
```
`kill -0 PID` —> sends `no signal` , just checks if the process exists. Returns 0 if it exists, 1 if not. Good for checking if a process is alive.

---

# Zombie Processes

A zombie is a process that has finished executing but its parent hasn't called wait() to collect its exit status. It stays in the process table as a ghost.

```bash
# How to find zombies:
ps aux | awk '$8 == "Z"'        # STAT column = Z means zombie
ps aux | grep -w Z               # grep for zombie state
```

Zombies themselves use almost no resources, but:

   - Too many zombies can exhaust the process table
   - It means the parent process has a bug — it's not reaping its children
   - The fix is usually to restart the parent process, not kill the zombie directly

## Why you can't kill a zombie directly

```shell
   kill -9 <zombie_pid>  # does nothing
```

A zombie is already dead — it has no running code. It's just a record in the process table waiting for its parent to call `wait()` and collect the exit status. The kernel won't
remove it until the parent does that.

## How to fix a zombie process

## Step 1 — Find the zombie and its parent

```shell
ps aux | awk '$8 == "Z"'                     # get zombie PIDs
ps -o ppid= -p <zombie_pid>                  # get parent PID
ps -o comm= -p <parent_pid>                  # get parent name
```
## Step 2 — Try sending SIGCHLD to the parent

```shell
kill -SIGCHLD <parent_pid>
```
SIGCHLD tells the parent "your child process finished, go collect it." Some parents respond to this and clean up.

## Step 3 — If that doesn't work, restart the parent

```bash
systemctl restart <parent_service>
```
Restarting the parent forces it to re-initialize, and the zombie gets reparented to init (PID 1) which immediately reaps it by calling the `wait()` in loop.

Then why still the Zombie process exists in the process table,

- The parent is alive but never calls wait() / waitpid() on its children. 
- The kernel keeps the process table entry because the exit status is still "owed" to the parent.
- The zombie sits there indefinitely as long as that parent keeps running

## Step 4 — If parent can't be restarted (critical service)

Sometimes zombies are temporary — the parent will eventually call wait(). A few zombies for a short time is normal. Only act if they accumulate.

## Step 5 — Last resort: reboot

If a process is spawning zombies uncontrollably and can't be restarted, a reboot clears everything.

When zombies are actually a problem

   - One or two zombies → probably fine, monitor
   - Dozens/hundreds of zombies
   - Zombies filling the process table (max ~32k PIDs on Linux) → system can't create new processes, critical

---

# Interview Questions on This Topic

## Signals

### Q: What's the difference between SIGTERM and SIGKILL?

SIGTERM is a request — the process can catch it, do cleanup, and exit gracefully. SIGKILL is enforced by the kernel directly, the process never even sees it, no cleanup happens. Always use SIGTERM first.

### Q: Can a process ignore SIGKILL?

No. SIGKILL and SIGSTOP are the only two signals that cannot be caught, blocked, or ignored. Everything else can be handled by the process.

### Q: What does kill -0 PID do?

Sends no signal. Just checks if the process exists and if you have permission to send signals to it. Returns exit code 0 if yes, non-zero if no. Used in scripts to check if process is alive without affecting it.

### Q: What signal does Ctrl+C send?

SIGINT (2). Ctrl+Z sends SIGTSTP (20). Ctrl+\ sends SIGQUIT (3).

---

## Processes & Zombies

### Q: What is a zombie process?

A process that has finished execution but hasn't been removed from the process table because its parent hasn't called wait() to collect its exit status. It appears as state Z in ps. It uses no CPU or memory but holds a PID slot.

### Q: How do you kill a zombie process?

You can't kill it directly — it's already dead. You fix it by sending SIGCHLD to the parent, or restarting the parent process. The parent needs to call wait(). If the parent is killed, the zombie gets reparented to init (PID 1) which reaps it immediately.

### Q: What is an orphan process?

The opposite of a zombie — a process whose parent died before it did. The orphan gets automatically reparented to PID 1 (init/systemd) which will reap it when it eventually exits. Orphans are mostly harmless.

### Q: What is the difference between a process and a thread?

A process has its own memory space, file descriptors, and PID. Threads share the memory space and file descriptors of their parent process but have their own stack and program counter. Threads are lighter to create but share state (race conditions risk). In ps, multi-threaded processes show l in the STAT column.

### Q: What does ps aux show vs ps -ef?

Both show all processes. ps aux is BSD-style — shows %CPU, %MEM, VSZ, RSS. ps -ef is POSIX-style — shows PPID (parent PID) and STIME. Use ps -ef when you need the parent PID, ps aux when you need resource usage.

### Q: How do you find what process is using a specific port?

```shell
lsof -i :8080          # shows process name and PID
ss -tlnp | grep 8080   # faster, shows PID too
```

### Q: What is the difference between VSZ and RSS?

VSZ (Virtual Size) = total virtual memory the process has mapped, including memory that may be swapped out or shared. RSS (Resident Set Size) = actual physical RAM currently in use by the process. RSS is what actually matters for memory pressure.

### Q: How do you find top memory-consuming processes?

```shell
ps aux --sort=-%mem | head -10     # Linux
ps aux -m | head -10               # macOS
```
### Q: A process is hung and not responding to SIGTERM. What do you do?

Wait a few seconds first (maybe it's doing cleanup). If still hung, use kill -9. Before force killing in production, check logs to understand why it hung — this is a bug that will happen again. After force kill, verify the service came back up and check for data corruption.

You can't kill it directly — it's already dead. You fix it by sending SIGCHLD to the parent, or restarting the parent process. The parent needs to call wait(). If the parent is killed, the zombie gets reparented to init (PID 1) which reaps it immediately.

### Q: What is an orphan process?

The opposite of a zombie — a process whose parent died before it did. The orphan gets automatically reparented to PID 1 (init/systemd) which will reap it when it eventually exits. Orphans are mostly harmless.

### Q: What is the difference between a process and a thread?

A process has its own memory space, file descriptors, and PID. Threads share the memory space and file descriptors of their parent process but have their own stack and program counter. Threads are lighter to create but share state (race conditions risk). In ps, multi-threaded processes show l in the STAT column.

### Q: What does ps aux show vs ps -ef?

Both show all processes. ps aux is BSD-style — shows %CPU, %MEM, VSZ, RSS. ps -ef is POSIX-style — shows PPID (parent PID) and STIME. Use ps -ef when you need the parent PID, ps aux when you need resource usage.

### Q: How do you find what process is using a specific port?

```bash
lsof -i :8080          # shows process name and PID
ss -tlnp | grep 8080   # faster, shows PID too
```
### Q: What is the difference between VSZ and RSS?

VSZ (Virtual Size) = total virtual memory the process has mapped, including memory that may be swapped out or shared. RSS (Resident Set Size) = actual physical RAM currently in use by the process. RSS is what actually matters for memory pressure.

### Q: How do you find top memory-consuming processes?

   ps aux --sort=-%mem | head -10     # Linux
   ps aux -m | head -10               # macOS

   Q: A process is hung and not responding to SIGTERM. What do you do?

   Wait a few seconds first (maybe it's doing cleanup). If still hung, use kill -9. Before force killing in production, check logs to understand why it hung — this is a bug that
   will happen again. After force kill, verify the service came back up and check for data corruption.

# Key Things to Remember

1. ps aux --sort=-%cpu — that - before %cpu means descending order. Without it you get lowest first.
2. awk '$8 ~ /^Z/' — the ~ operator matches a regex. $8 is the STAT column. ^Z means starts with Z (zombies can be Z, Zs, Z<, etc.).
3. ps -o ppid= -p PID — the = after ppid suppresses the column header. Clean output for scripting.
4. ps -o comm= -p PID — comm = command name only (no arguments). Use cmd or args if you want the full command with arguments.
5. Never kill -9 a zombie — it won't work. Zombies are already dead. Kill or restart the parent.
