## What is a Non-Interactive Shell?

A **non-interactive shell** is a shell that **does not allow user login or command interaction**.

Common examples:

* `/sbin/nologin`
* `/bin/false`

These are typically used for:

* System/service accounts (e.g., web servers, databases)
* Security (prevent direct login)

---

## Step 1: Create a User with Non-Interactive Shell

### Command:

```bash
sudo useradd -s /sbin/nologin devops_user
```

### Explanation:

* `useradd` → creates a new user
* `-s` → specifies the shell
* `/sbin/nologin` → disables login access

---

## Step 2: Set a Password (Optional)

Even if login is disabled, some systems require a password:

```bash
sudo passwd devops_user
```

Or lock it completely:

```bash
sudo passwd -l devops_user
```

---

## Step 3: Verify User Details

```bash
grep devops_user /etc/passwd
```

### Example Output:

```
devops_user:x:1001:1001::/home/devops_user:/sbin/nologin
```

---

## Step 4: Test Login Behavior

Try switching user:

```bash
su - devops_user
```

👉 Expected result:

```
This account is currently not available.
```

---

## Step 5: When to Use Non-Interactive Users

Use cases include:

* Running background services (e.g., nginx, mysql)
* CI/CD pipelines
* Cron jobs
* Application isolation

---

## Alternative: `/bin/false` vs `/sbin/nologin`

| Shell           | Behavior                     |
| --------------- | ---------------------------- |
| `/sbin/nologin` | Shows message + denies login |
| `/bin/false`    | Silently denies login        |

👉 Recommendation: **Use `/sbin/nologin`** (more informative)

---

## Bonus: Create System User (Best Practice)

```bash
sudo useradd -r -s /sbin/nologin app_user
```

* `-r` → system account (no home dir, lower UID range)

---

## Summary

* Non-interactive shells improve **security**
* Prevent unnecessary login access
* Ideal for **services and automation**
* Use `/sbin/nologin` for clarity
