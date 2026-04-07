# What is a Temporary User?

A **temporary user** is a Linux account that:

* Works normally for a limited time
* Gets **automatically disabled after a set date**

This is handled using **account expiration settings**

---

# Step 1: Create User with Expiry Date

### Command:

```bash
sudo useradd -e 2026-04-10 temp_user
```

### Explanation:

* `-e` → expiry date (format: `YYYY-MM-DD`)
* After this date → user **cannot log in**

---

# Step 2: Set Password

```bash
sudo passwd temp_user
```

---

# Step 3: Verify Expiry Settings

```bash
sudo chage -l temp_user
```

### Example Output:

```
Account expires : Apr 10, 2026
Password expires : never
```

---

# Step 4: Modify Expiry Date (if needed)

```bash
sudo chage -E 2026-04-15 temp_user
```

Useful if:

* Project deadline changes
* Access needs extension

---

# Step 5: Test Expired Account Behavior

After expiry date:

```bash
su - temp_user
```

Expected:

```
Account expired
```

---

# Step 6: Lock Account Manually (Immediate Disable)

```bash
sudo usermod -L temp_user
```

Unlock if needed:

```bash
sudo usermod -U temp_user
```

---

# Step 7: Delete Temporary User (Cleanup)

After usage:

```bash
sudo userdel -r temp_user
```

* `-r` → removes home directory

---

# Best Practices

* Always set **expiry for temporary users**
* Use strong passwords or SSH keys
* Monitor usage with logs (`/var/log/auth.log`)
* Remove users after task completion

---

# Set Expiry + Non-Interactive Shell

For extra security:

```bash
sudo useradd -e 2026-04-10 -s /sbin/nologin temp_service
```

Combines:

* **Time restriction**
* **No login access**

---

# Summary

* Use `-e` or `chage -E` to control expiry
* Ideal for **temporary access control**
* Improves **security & compliance**
* Always **clean up users after use**
