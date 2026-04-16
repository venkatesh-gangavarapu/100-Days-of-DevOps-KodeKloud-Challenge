# Day 18 — MariaDB Installation, Database Creation & User Privilege Management

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Database Administration / MariaDB  
**Difficulty:** Beginner–Intermediate  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

Full MariaDB setup on the Nautilus DB Server (`stdb01`):

1. Install and configure MariaDB server
2. Create database `kodekloud_db8`
3. Create user `kodekloud_tim` with password `YchZHRcLkL`
4. Grant full privileges on `kodekloud_db8` to `kodekloud_tim`

---

## 🧠 Concept — MariaDB vs PostgreSQL vs MySQL

### Key Differences

| Feature | MariaDB | PostgreSQL | MySQL |
|---------|---------|-----------|-------|
| Origin | MySQL fork (2009) | Independent (1996) | Oracle-owned |
| Drop-in replacement | MySQL ✅ | No | — |
| Auth method | `mysql -u root` (socket) | Peer auth (`postgres` user) | `mysql -u root` |
| Grant scope | `db.*` notation | Database then schema then table | `db.*` notation |
| Default port | 3306 | 5432 | 3306 |

### MariaDB User Host Syntax

MariaDB user accounts are defined as `'user'@'host'` — the host is part of the identity:

| Host value | Meaning |
|-----------|---------|
| `'localhost'` | Only from the local machine |
| `'%'` | From any host (wildcard) |
| `'192.168.1.%'` | From any IP in that subnet |
| `'stapp01'` | From that specific hostname only |

Using `'%'` is common for application users that connect from app servers. Using `'localhost'` restricts to local connections only.

### `GRANT ALL PRIVILEGES ON db.*` — What It Covers

```sql
GRANT ALL PRIVILEGES ON kodekloud_db8.* TO 'kodekloud_tim'@'%';
```

The `db.*` syntax means all tables, views, stored procedures, and functions within `kodekloud_db8`. This grants:

| Privilege | Description |
|-----------|-------------|
| SELECT | Read data |
| INSERT | Add rows |
| UPDATE | Modify rows |
| DELETE | Remove rows |
| CREATE | Create tables/views |
| DROP | Delete tables/views |
| INDEX | Manage indexes |
| ALTER | Modify table structure |
| REFERENCES | Foreign key constraints |

### Why `FLUSH PRIVILEGES`?

MariaDB caches grant table data in memory. `FLUSH PRIVILEGES` forces it to reload from disk immediately — ensuring changes take effect without a restart. It's required after direct manipulation of grant tables (`INSERT INTO mysql.user`), but technically not needed after `GRANT` statements (which flush automatically). It's good practice to include it anyway.

> **Real-world context:** MariaDB is the default database engine for many Linux distributions and is widely used for web application backends — WordPress, Drupal, Magento all support it natively. The installation and user provisioning pattern here is exactly what a DevOps engineer runs when spinning up a new application database. In cloud environments, this same workflow maps directly to RDS MariaDB instance setup via Terraform or AWS CLI.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Database Server (`stdb01`) |
| User | peter |
| DB Engine | MariaDB |
| New Database | `kodekloud_db8` |
| New DB User | `kodekloud_tim` |
| Password | `YchZHRcLkL` |
| Host scope | `%` (any host) |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into the database server

```bash
ssh peter@stdb01
```

### Step 2: Install MariaDB server and client

```bash
sudo yum install -y mariadb-server mariadb
```

### Step 3: Start and enable MariaDB

```bash
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

### Step 4: Verify MariaDB is running

```bash
sudo systemctl status mariadb
```

**Expected output:**
```
● mariadb.service - MariaDB database server
   Active: active (running)
   Loaded: loaded ... enabled
```

### Step 5: Connect to MariaDB as root

```bash
sudo mysql -u root
```

Fresh MariaDB installations on RHEL/CentOS allow passwordless root access via socket authentication. You should see the `MariaDB [(none)]>` prompt.

### Step 6: Create the database

```sql
CREATE DATABASE kodekloud_db8;
```

**Expected:**
```
Query OK, 1 row affected
```

### Step 7: Create the user

```sql
CREATE USER 'kodekloud_tim'@'%' IDENTIFIED BY 'YchZHRcLkL';
```

**Expected:**
```
Query OK, 0 rows affected
```

### Step 8: Grant full privileges

```sql
GRANT ALL PRIVILEGES ON kodekloud_db8.* TO 'kodekloud_tim'@'%';
```

**Expected:**
```
Query OK, 0 rows affected
```

### Step 9: Flush privileges and exit

```sql
FLUSH PRIVILEGES;
EXIT;
```

### Step 10: Verify everything was created correctly

```bash
# Check database exists
sudo mysql -u root -e "SHOW DATABASES;"

# Check user exists
sudo mysql -u root -e "SELECT User, Host FROM mysql.user WHERE User='kodekloud_tim';"

# Check grants
sudo mysql -u root -e "SHOW GRANTS FOR 'kodekloud_tim'@'%';"
```

**Expected grant output:**
```
GRANT ALL PRIVILEGES ON `kodekloud_db8`.* TO 'kodekloud_tim'@'%'
```

### Step 11: Test connection as the new user

```bash
mysql -u kodekloud_tim -pYchZHRcLkL -e "SHOW DATABASES;"
```

**Expected output includes:**
```
+--------------------+
| Database           |
+--------------------+
| kodekloud_db8      |
+--------------------+
```

✅ User created, database visible, full access confirmed.

---

## 📌 Commands Reference

```bash
# ─── Installation & Service ──────────────────────────────
sudo yum install -y mariadb-server mariadb
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl status mariadb

# ─── Connect as root ─────────────────────────────────────
sudo mysql -u root
sudo mysql -u root -p        # if root password is set

# ─── Database Operations ─────────────────────────────────
CREATE DATABASE kodekloud_db8;
SHOW DATABASES;
DROP DATABASE kodekloud_db8;  # careful!
USE kodekloud_db8;

# ─── User Operations ─────────────────────────────────────
CREATE USER 'kodekloud_tim'@'%' IDENTIFIED BY 'YchZHRcLkL';
SELECT User, Host FROM mysql.user;
DROP USER 'kodekloud_tim'@'%';
ALTER USER 'kodekloud_tim'@'%' IDENTIFIED BY 'newpassword';

# ─── Privilege Operations ────────────────────────────────
GRANT ALL PRIVILEGES ON kodekloud_db8.* TO 'kodekloud_tim'@'%';
SHOW GRANTS FOR 'kodekloud_tim'@'%';
REVOKE ALL PRIVILEGES ON kodekloud_db8.* FROM 'kodekloud_tim'@'%';
FLUSH PRIVILEGES;

# ─── One-liner non-interactive method ────────────────────
sudo mysql -u root -e "CREATE DATABASE kodekloud_db8;"
sudo mysql -u root -e "CREATE USER 'kodekloud_tim'@'%' IDENTIFIED BY 'YchZHRcLkL';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON kodekloud_db8.* TO 'kodekloud_tim'@'%';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

# ─── Test as new user ────────────────────────────────────
mysql -u kodekloud_tim -pYchZHRcLkL -e "SHOW DATABASES;"
```

---

## ⚠️ Common Mistakes to Avoid

1. **Forgetting `.*` in the GRANT statement** — `GRANT ALL ON kodekloud_db8` without `.*` is a syntax error. The dot-star syntax explicitly means "all tables in this database."
2. **Wrong host in user definition** — `'kodekloud_tim'@'localhost'` and `'kodekloud_tim'@'%'` are treated as completely different users in MariaDB. If the app connects from a remote host and the user is only defined for `localhost`, the connection is denied even with the correct password.
3. **Not running `FLUSH PRIVILEGES`** — While `GRANT` statements flush automatically, it's best practice to always run it after any privilege changes to ensure the cache is current.
4. **Not enabling MariaDB** — `systemctl start` without `enable` means the service won't start after a reboot. Always do both.
5. **Testing with only `SHOW DATABASES`** — This only confirms visibility. Always also verify `SHOW GRANTS` to confirm the privilege level is exactly what was intended.

---

## 🔍 MariaDB vs PostgreSQL — Side-by-Side Comparison (Days 17 & 18)

| Task | PostgreSQL (Day 17) | MariaDB (Day 18) |
|------|--------------------|--------------------|
| Access as superuser | `sudo su - postgres && psql` | `sudo mysql -u root` |
| Create user | `CREATE USER name WITH PASSWORD '...'` | `CREATE USER 'name'@'%' IDENTIFIED BY '...'` |
| Create database | `CREATE DATABASE name;` | `CREATE DATABASE name;` |
| Grant all | `GRANT ALL PRIVILEGES ON DATABASE` | `GRANT ALL PRIVILEGES ON db.*` |
| Apply changes | Immediate | `FLUSH PRIVILEGES;` |
| List databases | `\l` | `SHOW DATABASES;` |
| List users | `\du` | `SELECT User,Host FROM mysql.user;` |
| List grants | `\dp` | `SHOW GRANTS FOR 'user'@'host';` |

---

## 🔗 References

- [MariaDB CREATE USER](https://mariadb.com/kb/en/create-user/)
- [MariaDB GRANT](https://mariadb.com/kb/en/grant/)
- [MariaDB Server Installation — RHEL/CentOS](https://mariadb.com/kb/en/yum/)
- [MariaDB — Configuring MariaDB for Remote Client Access](https://mariadb.com/kb/en/configuring-mariadb-for-remote-client-access/)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: An application connects to MariaDB from another server but gets "Access denied for user". The user exists and the password is correct. What's wrong?**

```sql
-- Check what hosts the user is allowed from
SELECT User, Host FROM mysql.user WHERE User='kodekloud_tim';
-- If it shows: kodekloud_tim | localhost
-- But app connects from stapp01 → denied!

-- Fix: grant access from the correct host
GRANT ALL PRIVILEGES ON kodekloud_db8.* TO 'kodekloud_tim'@'stapp01' IDENTIFIED BY 'YchZHRcLkL';
-- Or use wildcard:
GRANT ALL PRIVILEGES ON kodekloud_db8.* TO 'kodekloud_tim'@'%' IDENTIFIED BY 'YchZHRcLkL';
FLUSH PRIVILEGES;
```

> In MariaDB/MySQL, `'user'@'localhost'` and `'user'@'%'` are completely separate user accounts. This is the #1 "access denied" mystery — the user exists for localhost but not for remote connections.

---

**Q2: What's the minimal set of privileges for an application database user in production?**

```sql
-- Instead of ALL PRIVILEGES, grant only what the app needs:
GRANT SELECT, INSERT, UPDATE, DELETE ON kodekloud_db8.* TO 'appuser'@'%';

-- For read-only reporting user:
GRANT SELECT ON kodekloud_db8.* TO 'readonly'@'%';

-- For a migration user (needs DDL):
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP ON kodekloud_db8.* TO 'migrate'@'localhost';
```

> Least privilege: grant exactly what the application needs. An app user rarely needs CREATE, DROP, or ALTER — those are migration privileges. A compromised app user with minimal grants can read/write data but can't drop tables or access other databases.

---

**Q3: How do you verify that a user has the exact privileges you expect — not more, not less?**

```sql
-- Show all grants for the user
SHOW GRANTS FOR 'kodekloud_tim'@'%';

-- Expected:
-- GRANT ALL PRIVILEGES ON `kodekloud_db8`.* TO 'kodekloud_tim'@'%'

-- Check from non-root — what databases does the user see?
mysql -u kodekloud_tim -pYchZHRcLkL -e "SHOW DATABASES;"
```

> `SHOW GRANTS` is the authoritative source. The output shows exactly what privilege string is stored — no guessing. Run it after every `GRANT` to confirm.

---

**Q4: MariaDB is freshly installed and you connect as root without a password. Is this a security problem?**

> Yes — passwordless root is the default on fresh MariaDB installs on RHEL/CentOS (using socket authentication). It's only safe because root requires `sudo` to access it. But you should still secure it:
>
> ```bash
> sudo mysql_secure_installation
> ```
>
> This guided script: sets a root password, removes anonymous users, disables remote root login, removes the test database. Run it after every fresh MariaDB install in production before deploying any applications.

---

**Q5: In Terraform/infrastructure-as-code, how would you provision this MariaDB user automatically?**

```hcl
# For AWS RDS MariaDB:
resource "aws_db_instance" "main" {
  engine         = "mariadb"
  engine_version = "10.6"
  username       = "admin"
  password       = var.db_password
  db_name        = "kodekloud_db8"
}

# Then use a null_resource + provisioner to create the app user:
resource "null_resource" "db_user" {
  provisioner "local-exec" {
    command = <<-EOF
      mysql -h ${aws_db_instance.main.endpoint} -u admin -p${var.db_password} \
        -e "CREATE USER 'kodekloud_tim'@'%' IDENTIFIED BY '${var.app_db_password}'; \
            GRANT ALL ON kodekloud_db8.* TO 'kodekloud_tim'@'%'; \
            FLUSH PRIVILEGES;"
    EOF
  }
}
```

> In modern infrastructure, database users are provisioned as code alongside the infrastructure. Passwords come from Vault or AWS Secrets Manager — never hardcoded in Terraform files.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
