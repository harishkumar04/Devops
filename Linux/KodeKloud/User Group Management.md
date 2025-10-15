# Task 

## Source : KodeKloud (Linux)

**The system admin team at xFusionCorp Industries has streamlined access management by implementing group-based access control. Here's what you need to do:**

**a. Create a group named nautilus_developers across all App servers within the Stratos Datacenter.**

**b. Add the user jarod into the nautilus_developers group on all App servers. If the user doesn't exist, create it as well.**

### Solution 1 :

```bash
ssh tony@stapp01

# 1. Create the group (if it doesn't exist)
sudo groupadd nautilus_developers

# 2. Check if user 'jarod' exists; if not, create it
id jarod || sudo useradd -m jarod

# 3. Add 'jarod' to the group. usermod -aG -> appends the user to the group without removing existing group memberships
sudo usermod -aG nautilus_developers jarod

# 4. Verify the user is in the group
id jarod
```

Like this repeat the process for each App server

### Solution 2 :

If i was the host

```bash
for server in stapp01 stapp02 stapp03; do
    ssh thor@$server "
        sudo groupadd nautilus_developers 2>/dev/null
        id jarod || sudo useradd -m jarod
        sudo usermod -aG nautilus_developers jarod
        id jarod
    "
done
```
_Note_ :2>/dev/null silences the “group already exists” warning.

