# Day 17 — PostgreSQL Database User Creation & Privilege Management

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Database Administration / PostgreSQL  
**Difficulty:** Beginner–Intermediate  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

Pre-requisite database setup for a new Nautilus application deployment on `stdb01`:

1. Create database user `kodekloud_rin` with password `B4zNgHA7Ya`
2. Create database `kodekloud_db2`
3. Grant full privileges on `kodekloud_db2` to `kodekloud_rin`
4. No PostgreSQL service restart allowed

---

## 🧠 Concept — PostgreSQL User & Privilege Management

### PostgreSQL vs MySQL Terminology

| Concept | PostgreSQL | MySQL |
|---------|-----------|-------|
| User account | `ROLE` or `USER` | `USER` |
| Instance | Cluster | Server |
| Permission scope | Database → Schema → Table | Database → Table |
| Superuser | `postgres` | `root` |
| Connect as system user | `sudo su - postgres` | `mysql -u root` |

### How PostgreSQL Authentication Works

PostgreSQL uses **peer authentication** by default for local connections — meaning the OS user must match the database user. The `postgres` OS user maps to the `postgres` DB superuser. This is why we `sudo su - postgres` before running `psql`.

```
OS User: peter    → No direct psql access as superuser
OS User: postgres → Maps to postgres DB superuser via peer auth
```

### GRANT ALL PRIVILEGES — What It Covers

`GRANT ALL PRIVILEGES ON DATABASE` grants:

| Privilege | Meaning |
|-----------|---------|
| `CONNECT` | Can connect to the database |
| `CREATE` | Can create schemas in the database |
| `TEMPORARY` | Can create temporary tables |

> **Important:** In PostgreSQL, `GRANT ALL ON DATABASE` does NOT automatically grant access to all tables within the database. For full table-level access, you'd additionally run `GRANT ALL ON ALL TABLES IN SCHEMA public TO user`. For this task, database-level grants are sufficient.

### User vs Role in PostgreSQL

```sql
CREATE USER kodekloud_rin ...   -- Creates role WITH LOGIN by default
CREATE ROLE kodekloud_rin ...   -- Creates role WITHOUT LOGIN by default
```

`CREATE USER` is shorthand for `CREATE ROLE ... WITH LOGIN`. For application users that need to connect, always use `CREATE USER`.

> **Real-world context:** Every application deployed in production gets its own dedicated database user — never the superuser. This is the **principle of least privilege** applied to databases. If the application is compromised, the attacker only has access to that application's database — not the entire PostgreSQL cluster. This is standard practice in SOC2, PCI-DSS, and every security framework.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Database Server (`stdb01`) |
| User | peter |
| DB Engine | PostgreSQL |
| New DB User | `kodekloud_rin` |
| Password | `B4zNgHA7Ya` |
| New Database | `kodekloud_db2` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into the database server

```bash
ssh peter@stdb01
```

### Step 2: Switch to the postgres system user

```bash
sudo su - postgres
```

This is required because PostgreSQL uses peer authentication — the `postgres` OS user is the only one with superuser access to the DB cluster by default.

### Step 3: Connect to PostgreSQL

```bash
psql
```

You should see the `postgres=#` prompt.

### Step 4: Create the database user with password

```sql
CREATE USER kodekloud_rin WITH PASSWORD 'B4zNgHA7Ya';
```

**Expected output:**
```
CREATE ROLE
```

### Step 5: Create the database

```sql
CREATE DATABASE kodekloud_db2;
```

**Expected output:**
```
CREATE DATABASE
```

### Step 6: Grant full privileges on the database to the user

```sql
GRANT ALL PRIVILEGES ON DATABASE kodekloud_db2 TO kodekloud_rin;
```

**Expected output:**
```
GRANT
```

### Step 7: Verify the user exists

```sql
\du
```

**Expected output:**
```
                   List of roles
 Role name      |         Attributes          | Member of
----------------+-----------------------------+-----------
 kodekloud_rin  |                             | {}
 postgres       | Superuser, Create role, ... | {}
```

### Step 8: Verify the database exists with correct owner

```sql
\l
```

**Expected output:**
```
                                List of databases
      Name       |  Owner   | Encoding |   Collate   |    Ctype
-----------------+----------+----------+-------------+-------------
 kodekloud_db2   | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8
 postgres        | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8
```

### Step 9: Verify privileges on the database

```sql
\l kodekloud_db2
```

Look for `kodekloud_rin=CTc/postgres` in the Access privileges column — `C` = CREATE, `T` = TEMPORARY, `c` = CONNECT. ✅

### Step 10: Exit psql

```sql
\q
```

### Step 11: Test connection as the new user

```bash
psql -U kodekloud_rin -d kodekloud_db2 -h localhost
```

Enter password `B4zNgHA7Ya` when prompted.

**Expected:** Clean connection to `kodekloud_db2` database. ✅

---

## 📌 Commands Reference

```bash
# ─── Access PostgreSQL ────────────────────────────────────
sudo su - postgres
psql

# ─── User Management ─────────────────────────────────────
-- Create user with password
CREATE USER kodekloud_rin WITH PASSWORD 'B4zNgHA7Ya';

-- List all users/roles
\du

-- Change password
ALTER USER kodekloud_rin WITH PASSWORD 'newpassword';

-- Drop user
DROP USER kodekloud_rin;

# ─── Database Management ─────────────────────────────────
-- Create database
CREATE DATABASE kodekloud_db2;

-- List databases
\l

-- Connect to database
\c kodekloud_db2

-- Drop database
DROP DATABASE kodekloud_db2;

# ─── Privilege Management ────────────────────────────────
-- Grant all on database
GRANT ALL PRIVILEGES ON DATABASE kodekloud_db2 TO kodekloud_rin;

-- Grant all on all tables in schema
GRANT ALL ON ALL TABLES IN SCHEMA public TO kodekloud_rin;

-- Revoke privileges
REVOKE ALL PRIVILEGES ON DATABASE kodekloud_db2 FROM kodekloud_rin;

-- View database privileges
\l kodekloud_db2

# ─── Connection Test ─────────────────────────────────────
psql -U kodekloud_rin -d kodekloud_db2 -h localhost

# ─── Useful psql Meta-Commands ───────────────────────────
\du          -- List roles/users
\l           -- List databases
\c dbname    -- Connect to database
\dt          -- List tables in current database
\dn          -- List schemas
\dp          -- List table privileges
\q           -- Quit
```

---

## ⚠️ Common Mistakes to Avoid

1. **Running `psql` as `peter` instead of `postgres`** — Peer auth will deny access. Always `sudo su - postgres` first.
2. **Forgetting the semicolon** — Every SQL statement in psql requires a `;` at the end. Without it, psql waits for more input instead of executing.
3. **Confusing `CREATE USER` and `CREATE ROLE`** — `CREATE USER` includes `LOGIN` by default. `CREATE ROLE` without `LOGIN` can't connect to the database.
4. **Not quoting the password** — The password must be in single quotes: `WITH PASSWORD 'B4zNgHA7Ya'`. Without quotes, PostgreSQL tries to parse it as SQL.
5. **Restarting PostgreSQL** — The task explicitly prohibits this. All changes (user creation, grants) take effect immediately without a restart.
6. **Assuming `GRANT ALL ON DATABASE` covers tables** — It only grants database-level privileges (CONNECT, CREATE, TEMPORARY). Table-level access requires separate grants on the schema/tables.

---

## 🔍 PostgreSQL Privilege Hierarchy

```
PostgreSQL Cluster
└── Database (kodekloud_db2)
      └── Schema (public)
            └── Tables / Views / Functions
                  └── Rows (Row-Level Security)

GRANT ALL ON DATABASE  → database-level access
GRANT ALL ON SCHEMA    → schema-level access
GRANT ALL ON ALL TABLES IN SCHEMA → table-level access
```

For full application access, production setups typically grant at all three levels.

---

## 🔗 References

- [PostgreSQL CREATE USER](https://www.postgresql.org/docs/current/sql-createuser.html)
- [PostgreSQL GRANT](https://www.postgresql.org/docs/current/sql-grant.html)
- [PostgreSQL Role Attributes](https://www.postgresql.org/docs/current/role-attributes.html)
- [PostgreSQL Authentication](https://www.postgresql.org/docs/current/client-authentication.html)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: An application user gets "FATAL: password authentication failed" when connecting to PostgreSQL. How do you debug it?**

```bash
# Step 1: Confirm the user exists
sudo su - postgres
psql -c "\du" | grep kodekloud_rin

# Step 2: Confirm the database exists
psql -c "\l" | grep kodekloud_db2

# Step 3: Check grants
psql -c "\l kodekloud_db2"   # Look for CTc/postgres in access privileges

# Step 4: Test connection as the user
psql -U kodekloud_rin -d kodekloud_db2 -h localhost

# Step 5: Check pg_hba.conf (auth method for localhost)
sudo grep "md5\|scram\|trust" /var/lib/pgsql/data/pg_hba.conf
# If method is 'ident' or 'peer' — password auth won't work for remote connections
```

> "Password authentication failed" can mean: wrong password, wrong user host config in pg_hba.conf, or the user doesn't have CONNECT privilege on the database.

---

**Q2: Why do you need to `sudo su - postgres` before running `psql`? Can't you just `sudo psql`?**

> PostgreSQL uses **peer authentication** by default for local connections. Peer auth checks that your OS username matches the database role name. The `postgres` OS user maps to the `postgres` DB superuser. If you run `sudo psql` as `peter`, peer auth checks if a role named `peter` exists with superuser privileges — which it doesn't.
>
> `sudo su - postgres` switches to the OS `postgres` user first — then peer auth passes. Alternatively, use: `sudo -u postgres psql` (same result, one command).

---

**Q3: What's the difference between `GRANT ALL ON DATABASE` and `GRANT ALL ON ALL TABLES`?**

> `GRANT ALL ON DATABASE kodekloud_db2 TO kodekloud_rin` grants:
> - CONNECT — can connect to the database
> - CREATE — can create schemas
> - TEMPORARY — can create temp tables
>
> But NOT table access. For the application to actually SELECT/INSERT/UPDATE data, you need:
> ```sql
> \c kodekloud_db2
> GRANT ALL ON ALL TABLES IN SCHEMA public TO kodekloud_rin;
> GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO kodekloud_rin;
> ```
>
> This is the most common PostgreSQL privilege mistake — database-level grants don't cascade down to tables.

---

**Q4: How do you rotate a database user's password without downtime?**

```sql
-- Change the password
ALTER USER kodekloud_rin WITH PASSWORD 'NewSecureP@ss123';
-- Takes effect immediately — no restart needed
```

> Update the application's connection string (environment variable, secret manager, config file) in the same deployment. In Kubernetes, this means updating the Secret and rolling the pods. PostgreSQL accepts the new password immediately — no service restart required.

---

**Q5: In production, how do you securely create a database user without the password appearing in shell history?**

```bash
# Method 1: Use a heredoc (password in stdin, not command line)
sudo -u postgres psql << 'EOF'
CREATE USER kodekloud_rin WITH PASSWORD 'B4zNgHA7Ya';
EOF

# Method 2: Use PGPASSWORD env var (still risky — shows in process list)
PGPASSWORD='B4zNgHA7Ya' psql -U kodekloud_rin -d kodekloud_db2 -h localhost

# Method 3: Read password from a file (most secure)
sudo -u postgres psql -c "CREATE USER kodekloud_rin WITH PASSWORD '$(cat /run/secrets/db_password)';"

# Method 4: Ansible vault
- name: Create DB user
  community.postgresql.postgresql_user:
    name: kodekloud_rin
    password: "{{ vault_db_password }}"
```

> Passwords typed directly in shell commands appear in `.bash_history` and process listings (`ps aux`). Use heredocs, env files, or secrets managers in production.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
