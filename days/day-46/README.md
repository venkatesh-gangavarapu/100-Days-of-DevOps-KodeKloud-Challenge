# Day 46 — Full Stack Docker Compose: PHP+Apache & MariaDB (LAMP Stack)

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker Compose / Full Stack  
**Difficulty:** Intermediate  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

Deploy a complete containerized LAMP stack on **App Server 3** (`stapp03`) using Docker Compose at `/opt/security/docker-compose.yml`:

**Web service (`php_host`):**
- Image: `php:8.2-apache`
- Port: host `6200` → container `80`
- Volume: `/var/www/html` ↔ `/var/www/html`

**DB service (`mysql_host`):**
- Image: `mariadb:latest`
- Port: host `3306` → container `3306`
- Volume: `/var/lib/mysql` ↔ `/var/lib/mysql`
- Environment: `MYSQL_DATABASE=database_host`, custom user + password

---

## 🧠 Concept — Multi-Service Docker Compose Stack

### The LAMP Stack in Containers

LAMP (Linux, Apache, MySQL/MariaDB, PHP) is one of the most common web application stacks. In containers:

```
curl http://stapp03:6200/
        │
        ▼
php_host container (php:8.2-apache)
  Apache on port 80 → serves PHP files from /var/www/html
        │
        └── connects to ──►
                            mysql_host container (mariadb:latest)
                            MariaDB on port 3306
                            database: database_host
```

### Service Dependencies & Environment Variables

The `db` service uses environment variables to configure MariaDB at first startup:

| Variable | Purpose |
|----------|---------|
| `MYSQL_DATABASE` | Creates this database on init |
| `MYSQL_USER` | Creates this non-root user |
| `MYSQL_PASSWORD` | Password for the custom user |
| `MYSQL_ROOT_PASSWORD` | Required — sets root password |

**Why a custom user instead of root?** Same principle as Day 17 and 18 — least privilege. The application connects as `devuser` with access only to `database_host`. If the application is compromised, the attacker can't access or drop other databases or system tables.

### Volume Strategy

Both services use bind mounts to host directories:

```
/var/www/html  ↔  php_host:/var/www/html     ← web files on host
/var/lib/mysql ↔  mysql_host:/var/lib/mysql  ← DB data on host
```

This ensures:
- Web content managed on the host persists across container restarts
- Database data survives `docker compose down` — no data loss
- Files can be updated on host without restarting containers

> **Real-world context:** This docker-compose.yml represents a complete development and staging environment for any PHP web application — WordPress, Laravel, custom apps. The same pattern is used by millions of developers. Production would add `depends_on`, health checks, secrets management for passwords, and potentially separate the DB to a managed service (AWS RDS), but the fundamental Compose structure is identical.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 3 (`stapp03`) |
| User | banner |
| Compose file | `/opt/security/docker-compose.yml` |
| Web container | `php_host` — `php:8.2-apache` |
| DB container | `mysql_host` — `mariadb:latest` |
| Web port | `6200:80` |
| DB port | `3306:3306` |
| Database name | `database_host` |
| DB user | `devuser` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 3

```bash
ssh banner@stapp03
```

### Step 2: Create the directory

```bash
sudo mkdir -p /opt/security
```

### Step 3: Create docker-compose.yml

```bash
sudo vi /opt/security/docker-compose.yml
```

### The docker-compose.yml

```yaml
version: '3'
services:
  web:
    image: php:8.2-apache
    container_name: php_host
    ports:
      - "6200:80"
    volumes:
      - /var/www/html:/var/www/html

  db:
    image: mariadb:latest
    container_name: mysql_host
    ports:
      - "3306:3306"
    volumes:
      - /var/lib/mysql:/var/lib/mysql
    environment:
      MYSQL_DATABASE: database_host
      MYSQL_USER: devuser
      MYSQL_PASSWORD: Dev@Secure#2024
      MYSQL_ROOT_PASSWORD: Root@Secure#2024
```

### Step 4: Deploy the stack

```bash
cd /opt/security
sudo docker compose up -d
```

**Expected output:**
```
[+] Running 2/2
 ✔ Container php_host    Started
 ✔ Container mysql_host  Started
```

### Step 5: Verify both containers are running

```bash
sudo docker ps
```

**Expected:**
```
NAMES        IMAGE            PORTS
php_host     php:8.2-apache   0.0.0.0:6200->80/tcp
mysql_host   mariadb:latest   0.0.0.0:3306->3306/tcp
```

### Step 6: Test web service

```bash
curl http://localhost:6200/
```

### Step 7: Verify DB is accessible

```bash
sudo docker exec mysql_host mysql -u devuser -pDev@Secure#2024 \
  -e "SHOW DATABASES;"
# Expected: database_host listed ✅
```

---

## 📌 Commands Reference

```bash
# ─── Setup ───────────────────────────────────────────────
sudo mkdir -p /opt/security
sudo vi /opt/security/docker-compose.yml

# ─── Deploy ──────────────────────────────────────────────
cd /opt/security
sudo docker compose up -d
sudo docker compose ps                  # Service status
sudo docker compose logs                # All logs
sudo docker compose logs web            # Web service logs only
sudo docker compose logs db             # DB service logs only

# ─── Verify ──────────────────────────────────────────────
sudo docker ps
curl http://localhost:6200/
sudo docker exec mysql_host mysql -u devuser -pDev@Secure#2024 \
  -e "SHOW DATABASES;"

# ─── Teardown ────────────────────────────────────────────
sudo docker compose down                # Stop + remove containers
sudo docker compose down -v             # Also remove volumes
```

---

## ⚠️ Common Mistakes to Avoid

1. **Using root as MySQL user** — The task says use any custom user except root. Always create a dedicated app user with least privilege.
2. **Missing `MYSQL_ROOT_PASSWORD`** — MariaDB requires root password to be set, even if the app connects as a custom user. Without it, the container fails to start.
3. **Wrong file location** — Must be `/opt/security/docker-compose.yml` exactly. Any variation fails validation.
4. **Not quoting ports** — `6200:80` should be `"6200:80"` to prevent YAML from misinterpreting it.
5. **Forgetting host volume directories** — If `/var/www/html` or `/var/lib/mysql` don't exist on the host, Docker creates them automatically as root-owned — which may cause permission issues. Create them first with correct ownership if needed.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: How do containers in the same Docker Compose stack communicate with each other?**

Docker Compose automatically creates a default bridge network for all services in the stack. Containers on this network can reach each other using the **service name** as the hostname — not the container name. So the PHP application connects to MariaDB using `db` as the hostname (the service name), not `mysql_host` (the container name). This DNS-based service discovery is one of the key advantages of Compose over plain `docker run`. The connection string in the PHP app would be something like `mysqli_connect('db', 'devuser', 'Dev@Secure#2024', 'database_host')`.

---

**Q2: What is `depends_on` in Docker Compose and why wasn't it used here?**

`depends_on` tells Compose to start one service before another. Adding `depends_on: [db]` to the web service ensures MariaDB starts before PHP+Apache. However, `depends_on` only waits for the container to start — not for MariaDB to be ready to accept connections. A newly started MariaDB container takes several seconds to initialize. For production, you'd use a healthcheck: define a `healthcheck` on the db service that runs `mysqladmin ping`, and use `depends_on: condition: service_healthy` in the web service. For this task, the basic form is sufficient since the FINISH button redeploys the stack and validation doesn't test DB connectivity timing.

---

**Q3: Why is `MYSQL_ROOT_PASSWORD` required even when using a custom user?**

MariaDB's Docker image initialization requires `MYSQL_ROOT_PASSWORD` to be set — it's used to initialize the database system tables and set the root account password. Without it, the container exits immediately with an error. The custom user (`MYSQL_USER`, `MYSQL_PASSWORD`) is created alongside root during initialization — it doesn't replace root, it's an additional account. In production, the root password should be a strong random string stored in a secrets manager, and the application should only ever connect using the custom user.

---

**Q4: What happens to the MariaDB data if you run `docker compose down` and `docker compose up` again?**

With the bind mount `/var/lib/mysql:/var/lib/mysql`, the database files live on the host — not inside the container. `docker compose down` removes the containers but the `/var/lib/mysql` directory on the host remains untouched with all your data intact. When you `docker compose up` again, MariaDB detects the existing data directory, skips initialization, and resumes with all your databases and data exactly as you left them. Only `docker compose down -v` (which removes named volumes) or manually deleting `/var/lib/mysql` on the host would cause data loss.

---

**Q5: How would you manage secrets like database passwords in a production Docker Compose deployment?**

Hardcoding passwords in `docker-compose.yml` is a security risk — the file gets committed to version control, exposing credentials. Production approaches: (1) **Docker Secrets** (`secrets:` in Compose) — stores sensitive data in encrypted files, accessible only to specified services. (2) **Environment file** — store variables in a `.env` file excluded from version control, referenced as `${MYSQL_PASSWORD}` in the Compose file. (3) **External secrets manager** — AWS Secrets Manager, HashiCorp Vault, or similar, with application code fetching credentials at runtime. The `.env` file approach is the minimum viable improvement: `MYSQL_PASSWORD=Dev@Secure#2024` in `.env`, `MYSQL_PASSWORD: ${MYSQL_PASSWORD}` in the Compose file, and `.env` in `.gitignore`.

---

**Q6: How does this Docker Compose stack map to a Kubernetes deployment?**

Each Compose service becomes a Kubernetes Deployment (or StatefulSet for the DB). The `ports` mapping becomes a Service resource. The `volumes` bind mount becomes a PersistentVolumeClaim. Environment variables become a ConfigMap (non-sensitive) or Secret (sensitive). The automatic Compose networking becomes a Kubernetes Service with DNS. `docker compose up -d` becomes `kubectl apply -f deployment.yaml`. The conceptual model is identical — the YAML syntax and resource types differ. Tools like Kompose can automatically convert a `docker-compose.yml` to Kubernetes manifests as a starting point.

---

## 🔗 References

- [Docker Hub — php](https://hub.docker.com/_/php)
- [Docker Hub — mariadb](https://hub.docker.com/_/mariadb)
- [Docker Compose — Environment Variables](https://docs.docker.com/compose/environment-variables/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
