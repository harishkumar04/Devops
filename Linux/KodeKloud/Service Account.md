# Task

**In response to the latest tool implementation at xFusionCorp Industries, the system admins require the creation of a service user account. Here are the specifics:**
- **Create a user named yousuf in App Server 1 without a home directory.**

# Solution

# connect to App Server 1
ssh tony@stapp01

# create a system/service user 'yousuf' with no home directory and no interactive shell
sudo useradd -r -M -s /sbin/nologin -c "service account for backup/agent" yousuf

# verify the account exists and show its entry
getent passwd yousuf

# show UID/GID and groups for the user
id yousuf
