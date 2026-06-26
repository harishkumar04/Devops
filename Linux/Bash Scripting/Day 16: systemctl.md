  What is systemd?

   When Linux boots, something has to start all the services — SSH, networking, databases, web servers, etc. That "something" is systemd, and it's the init system on almost every
   modern Linux distro (Ubuntu, Debian, CentOS, RHEL, Arch).

   systemctl is the command you use to talk to systemd.

   You → systemctl → systemd → service (nginx, sshd, etc.)

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   Core Concepts

   Unit

   Everything in systemd is a unit. A service is just one type of unit.

   ┌───────────┬───────────┬─────────────────────────────────┐
   │ Unit Type │ Extension │ What it is                      │
   ├───────────┼───────────┼─────────────────────────────────┤
   │ Service   │ .service  │ A daemon/process (nginx, sshd)  │
   ├───────────┼───────────┼─────────────────────────────────┤
   │ Timer     │ .timer    │ Like cron jobs                  │
   ├───────────┼───────────┼─────────────────────────────────┤
   │ Socket    │ .socket   │ Network socket activation       │
   ├───────────┼───────────┼─────────────────────────────────┤
   │ Target    │ .target   │ Group of units (like runlevels) │
   └───────────┴───────────┴─────────────────────────────────┘

   Service States

   active (running)   → process is up
   active (exited)    → ran once and exited cleanly (e.g. a one-shot script)
   inactive (dead)    → stopped
   failed             → crashed or exited with error
   activating         → starting up
   deactivating       → shutting down

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   Essential Commands

   Check status

   systemctl status nginx
   systemctl status sshd
   systemctl status nginx.service   # same thing, .service is optional

   Start / Stop / Restart

   systemctl start nginx
   systemctl stop nginx
   systemctl restart nginx
   systemctl reload nginx    # reload config without full restart (if supported)

   Enable / Disable (survives reboot)

   systemctl enable nginx    # start on boot
   systemctl disable nginx   # don't start on boot
   systemctl is-enabled nginx

   Check if running

   systemctl is-active nginx    # prints "active" or "inactive", exit code 0 or 1
   systemctl is-failed nginx    # prints "failed" if crashed

   List services

   systemctl list-units --type=service           # all loaded services
   systemctl list-units --type=service --state=running   # only running
   systemctl list-units --type=service --state=failed    # only failed

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   Reading systemctl status output

   ● nginx.service - A high performance web server
        Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
        Active: active (running) since Fri 2026-06-26 09:00:00 IST; 5h ago
          Docs: man:nginx(8)
      Main PID: 1234 (nginx)
         Tasks: 2 (limit: 4915)
        Memory: 3.5M
           CPU: 210ms
        CGroup: /system.slice/nginx.service
                ├─1234 nginx: master process
                └─1235 nginx: worker process

   Jun 26 09:00:00 hostname nginx[1234]: Starting nginx...

   Key fields:

   - Loaded → config file path + whether it's enabled on boot
   - Active → current state + how long it's been running
   - Main PID → the process ID
   - CGroup → all processes belonging to this service
   - Bottom lines → recent logs (last ~10 lines from journald)

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   Unit File Anatomy

   Unit files live in /lib/systemd/system/ (system) or /etc/systemd/system/ (your custom ones).

   [Unit]
   Description=My App
   After=network.target       # start after networking is up

   [Service]
   Type=simple
   User=appuser
   WorkingDirectory=/opt/myapp
   ExecStart=/opt/myapp/start.sh
   Restart=on-failure         # auto-restart if it crashes
   RestartSec=5

   [Install]
   WantedBy=multi-user.target  # enable for normal multi-user boot

   After editing a unit file:

   systemctl daemon-reload    # tell systemd to re-read unit files
   systemctl restart myapp

   ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

   Bash + systemctl patterns you'll use constantly

   # check if service is active (use in scripts)
   if systemctl is-active --quiet nginx; then
       echo "nginx is running"
   fi

   # restart if not running
   systemctl is-active --quiet nginx || systemctl start nginx

   # get just the active state as a string
   systemctl is-active nginx   # prints: active / inactive / failed

   # check exit code (0 = active, non-zero = not active)
   systemctl is-active --quiet nginx
   echo $?

   --quiet suppresses the text output — you only care about the exit code in scripts.
