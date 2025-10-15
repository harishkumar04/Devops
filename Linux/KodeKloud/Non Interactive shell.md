# Task

**To accommodate the backup agent tool's specifications, the system admin team at xFusionCorp Industries requires the creation of a user with a non-interactive shell.**
**Here's your task:**
 - **Create a user named kareem with a non-interactive shell on App Server 3**

# Solution :

```bash
ssh banner@stapp03

sudo useradd -s /sbin/nologin kareem
# Or
sudo useradd -s /bin/false kareem

# check
grep kareem /etc/passwd
or
su - kareem
```
