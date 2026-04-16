# Day 19 — Apache Multi-Directory Hosting on Custom Port (5002)

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Web Server / Apache / Static Site Hosting  
**Difficulty:** Intermediate  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

Deploy two static websites on **App Server 3** (`stapp03`) under a single Apache instance:

- Install `httpd` on App Server 3
- Configure Apache to listen on port `5002`
- Copy `blog` and `apps` directories from jump host
- Serve both under the same document root:
  - `http://localhost:5002/blog/`
  - `http://localhost:5002/apps/`

---

## 🧠 Concept — Path-Based Hosting vs Virtual Hosting

### Two Ways to Host Multiple Sites on Apache

| Method | How it works | Use case |
|--------|-------------|---------|
| **Path-based** (this task) | Single server block, multiple subdirectories | Same domain, different URL paths |
| **Virtual hosting** | Separate server blocks per site | Different domains or subdomains |

**Path-based hosting** is simpler — both sites live under the same document root in their own subdirectories. Apache serves them based on the URL path, no additional configuration needed beyond placing the files correctly.

```
/var/www/html/          ← Document root
  ├── blog/             ← Served at /blog/
  │   └── index.html
  └── apps/             ← Served at /apps/
      └── index.html
```

When a request comes in for `http://localhost:5002/blog/`, Apache maps it to `/var/www/html/blog/` automatically — no Alias or Location directive needed.

### Why SELinux Context Matters for Web Files

Files copied from `/tmp/` or other non-standard locations retain their original SELinux label. Apache (running as `httpd_t`) can only read files labelled as `httpd_sys_content_t`. Without `restorecon`, Apache returns 403 Forbidden even when filesystem permissions are correct.

```
File in /tmp/        → label: tmp_t          → Apache CANNOT read
File in /var/www/html/ → label: httpd_sys_content_t → Apache CAN read
restorecon -Rv /var/www/html/ → fixes labels on copied files
```

### Apache Port Change Requirements

Changing from port 80 to 5002 requires three independent changes:

| Layer | Action |
|-------|--------|
| `httpd.conf` | Change `Listen 80` → `Listen 5002` |
| SELinux | Add 5002 to `http_port_t` |
| Firewall | Allow inbound on 5002 (if needed for remote access) |

> **Real-world context:** Path-based multi-site hosting is extremely common in staging and development environments where multiple apps share a single server. It's also the foundation of how many CMS platforms (WordPress multisite, for example) work. Understanding how Apache maps URL paths to filesystem directories is fundamental web server knowledge.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Jump Host | Source of website files |
| App Server 3 | `stapp03` — user `banner` |
| Apache Port | `5002` |
| Document Root | `/var/www/html/` |
| Blog path | `/var/www/html/blog/` → `http://localhost:5002/blog/` |
| Apps path | `/var/www/html/apps/` → `http://localhost:5002/apps/` |

---

## 🔧 Solution — Step by Step

### Phase 1: Transfer Website Files from Jump Host

```bash
# Run from jump host as thor
scp -r /home/thor/blog banner@stapp03:/tmp/
scp -r /home/thor/apps banner@stapp03:/tmp/
```

### Phase 2: Configure App Server 3

#### Step 1: SSH into App Server 3

```bash
ssh banner@stapp03
```

#### Step 2: Install Apache

```bash
sudo yum install -y httpd
```

#### Step 3: Move website files to document root

```bash
sudo cp -r /tmp/blog /var/www/html/
sudo cp -r /tmp/apps /var/www/html/
```

#### Step 4: Set correct ownership and permissions

```bash
sudo chown -R apache:apache /var/www/html/blog
sudo chown -R apache:apache /var/www/html/apps
sudo chmod -R 755 /var/www/html/blog
sudo chmod -R 755 /var/www/html/apps
```

#### Step 5: Fix SELinux context on copied files

```bash
sudo restorecon -Rv /var/www/html/
```

This relabels all files to `httpd_sys_content_t` — required for Apache to serve them under SELinux enforcing mode.

#### Step 6: Change Apache port from 80 to 5002

```bash
sudo sed -i 's/^Listen.*/Listen 5002/' /etc/httpd/conf/httpd.conf
```

**Verify:**
```bash
grep "^Listen" /etc/httpd/conf/httpd.conf
# Expected: Listen 5002
```

#### Step 7: Allow port 5002 in SELinux

```bash
sudo semanage port -a -t http_port_t -p tcp 5002
```

**Verify:**
```bash
sudo semanage port -l | grep http_port_t
# Expected: http_port_t  tcp  5002, 80, 81, 443, ...
```

> Install semanage if missing: `sudo yum install -y policycoreutils-python-utils`

#### Step 8: Validate Apache configuration syntax

```bash
sudo httpd -t
# Expected: Syntax OK
```

#### Step 9: Start and enable Apache

```bash
sudo systemctl start httpd
sudo systemctl enable httpd
```

#### Step 10: Verify service and port

```bash
sudo systemctl status httpd
sudo ss -tlnp | grep 5002
# Expected: httpd listening on 5002
```

#### Step 11: Test both paths

```bash
curl http://localhost:5002/blog/
curl http://localhost:5002/apps/
```

**Expected:** HTML content from each site — no 403, no 404. ✅

---

## 📌 Commands Reference

```bash
# ─── Jump Host: Transfer Files ───────────────────────────
scp -r /home/thor/blog banner@stapp03:/tmp/
scp -r /home/thor/apps banner@stapp03:/tmp/

# ─── App Server 3: Install Apache ────────────────────────
sudo yum install -y httpd

# ─── Move Files to Document Root ─────────────────────────
sudo cp -r /tmp/blog /var/www/html/
sudo cp -r /tmp/apps /var/www/html/

# ─── Permissions & Ownership ─────────────────────────────
sudo chown -R apache:apache /var/www/html/blog /var/www/html/apps
sudo chmod -R 755 /var/www/html/blog /var/www/html/apps

# ─── SELinux Context Fix ──────────────────────────────────
sudo restorecon -Rv /var/www/html/

# ─── Port Configuration ──────────────────────────────────
sudo sed -i 's/^Listen.*/Listen 5002/' /etc/httpd/conf/httpd.conf
grep "^Listen" /etc/httpd/conf/httpd.conf     # Verify

# ─── SELinux Port Allow ───────────────────────────────────
sudo semanage port -a -t http_port_t -p tcp 5002
sudo semanage port -l | grep http_port_t      # Verify

# ─── Config Validation & Service ─────────────────────────
sudo httpd -t                                 # Syntax check
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl status httpd

# ─── Verification ────────────────────────────────────────
sudo ss -tlnp | grep 5002
curl http://localhost:5002/blog/
curl http://localhost:5002/apps/

# ─── Debug 403 Forbidden ─────────────────────────────────
ls -laZ /var/www/html/blog/                   # Check SELinux labels
sudo tail -20 /var/log/httpd/error_log        # Check error log
```

---

## ⚠️ Common Mistakes to Avoid

1. **Copying to wrong location** — Files must be in `/var/www/html/blog/` and `/var/www/html/apps/` — not `/var/www/blog/` or anywhere else outside the document root.
2. **Skipping `restorecon`** — Copied files from `/tmp/` carry the `tmp_t` SELinux label. Apache can't serve them. Always run `restorecon -Rv /var/www/html/` after copying.
3. **Wrong ownership** — Files owned by `root` instead of `apache` can cause permission issues. `chown -R apache:apache` ensures the web server process can read them.
4. **Forgetting the trailing slash in the URL** — `curl http://localhost:5002/blog` (no trailing slash) may return a redirect. `curl http://localhost:5002/blog/` (with slash) hits the directory directly.
5. **Skipping SELinux port allowance** — Port 5002 is not in `http_port_t` by default. Without `semanage port -a`, Apache fails to bind even if `httpd.conf` says `Listen 5002`.
6. **Not running `httpd -t`** — Always validate config before restarting.

---

## 🔍 How Apache Maps URL Paths to Filesystem

```
Request: GET http://localhost:5002/blog/index.html

Apache lookup:
  DocumentRoot = /var/www/html
  Request path = /blog/index.html
  File served  = /var/www/html/blog/index.html

Request: GET http://localhost:5002/apps/

Apache lookup:
  DocumentRoot = /var/www/html
  Request path = /apps/
  File served  = /var/www/html/apps/index.html (DirectoryIndex)
```

No special Alias or Location directives needed — Apache's `DocumentRoot` handles the mapping automatically for subdirectories.

---

## 🔗 References

- [Apache httpd — DocumentRoot](https://httpd.apache.org/docs/2.4/mod/core.html#documentroot)
- [Apache httpd — Directory Permissions](https://httpd.apache.org/docs/2.4/sections.html)
- [SELinux — httpd Context](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/using-selinux-with-a-server-application_using-selinux)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: Files were copied to `/var/www/html/blog/` with correct permissions, but Apache returns 403 Forbidden. What's the SELinux issue?**

```bash
# Check the SELinux context on the files
ls -Z /var/www/html/blog/
# system_u:object_r:tmp_t:s0  index.html  ← wrong! Should be httpd_sys_content_t

# Files copied from /tmp/ keep the tmp_t label
# Fix: restore correct context
sudo restorecon -Rv /var/www/html/

# Verify
ls -Z /var/www/html/blog/
# system_u:object_r:httpd_sys_content_t:s0  index.html  ✅

# Also check the error log for confirmation:
sudo tail -20 /var/log/httpd/error_log
# AVC denied: httpd read tmp_t → confirms SELinux was the cause
```

> This is the single most common cause of "403 after copying files" on RHEL/CentOS. Always run `restorecon -Rv` after copying web content from any non-standard source location.

---

**Q2: You changed Apache to listen on port 5002 and it starts fine, but `curl http://localhost:5002/blog/` still refuses. What else needs changing?**

```bash
# Check if port 5002 is actually bound
sudo ss -tlnp | grep 5002

# If not bound — check SELinux port context
sudo semanage port -l | grep http_port_t
# If 5002 is missing:
sudo semanage port -a -t http_port_t -p tcp 5002

# Restart Apache after adding port context
sudo systemctl restart httpd

# Verify binding
sudo ss -tlnp | grep 5002
```

> Apache will silently fail to bind to a non-standard port if SELinux doesn't have it in `http_port_t`. The service may appear to start (if other ports are fine) but won't bind to 5002. Always check `semanage port -l | grep http_port_t` after any port change.

---

**Q3: How does Apache automatically route `/blog/` requests to the `/var/www/html/blog/` directory without any Alias directive?**

> Apache's `DocumentRoot` directive defines the filesystem root for all URL paths. When Apache receives `GET /blog/index.html`:
>
> ```
> URL path: /blog/index.html
> DocumentRoot: /var/www/html
> Mapped to: /var/www/html/blog/index.html
> ```
>
> Path concatenation: DocumentRoot + URL path = filesystem path. No special config needed for subdirectories — they're served automatically as long as they're inside the DocumentRoot with correct permissions and SELinux labels.

---

**Q4: What ownership should web files have — `root:root` or `apache:apache`?**

> For files Apache needs to **read** (static HTML, CSS, images): `root:root` with `644` permissions is fine — Apache can read world-readable files.
>
> For files Apache needs to **write** (uploads, cache): `apache:apache` with `755` is required — Apache's process runs as the `apache` user and needs write access.
>
> `chown -R apache:apache` is the safe default for all web content — it's more permissive than necessary for read-only files but ensures no permission issues.

---

**Q5: How would you host 5 websites on a single Apache server using virtual hosts instead of path-based hosting?**

```apache
# /etc/httpd/conf.d/sites.conf

<VirtualHost *:80>
    ServerName blog.example.com
    DocumentRoot /var/www/blog
</VirtualHost>

<VirtualHost *:80>
    ServerName apps.example.com
    DocumentRoot /var/www/apps
</VirtualHost>
```

> Virtual hosting routes requests based on the `Host` header — different domains go to different document roots. Path-based hosting (this task) serves multiple sites under one domain via URL paths. Virtual hosting is more common for distinct applications; path-based is simpler when all content is on the same domain.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
