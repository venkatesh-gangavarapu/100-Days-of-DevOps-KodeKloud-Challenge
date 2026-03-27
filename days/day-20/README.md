# Day 20 — nginx + PHP-FPM 8.2 Integration via Unix Socket

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Web Server / PHP / nginx / Application Stack  
**Difficulty:** Intermediate–Advanced  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

Deploy a production-ready PHP stack on **App Server 1** (`stapp01`):

- Install **nginx** on port `8098` with document root `/var/www/html`
- Install **PHP-FPM 8.2** using Unix socket `/var/run/php-fpm/default.sock`
- Configure nginx to pass PHP requests to php-fpm through the socket
- Verify: `curl http://stapp01:8098/index.php` from jump host

---

## 🧠 Concept — nginx + PHP-FPM Architecture

### Why nginx Doesn't Execute PHP Directly

nginx is a pure HTTP server — it serves static files extremely efficiently but has no built-in PHP interpreter. PHP execution is handled by a separate process manager: **PHP-FPM (FastCGI Process Manager)**.

```
HTTP Request (index.php)
        │
        ▼
    nginx :8098
        │
        ├── Static file? (.html, .css, .js)  → serve directly
        │
        └── PHP file? (.php)
              │
              └── FastCGI proxy → Unix socket
                                        │
                                        ▼
                                   PHP-FPM 8.2
                                   (executes PHP)
                                        │
                                        └── Response back to nginx → client
```

### Unix Socket vs TCP Socket

php-fpm can listen on either a Unix socket or a TCP port:

| Method | Example | Performance | Use case |
|--------|---------|-------------|---------|
| Unix socket | `/var/run/php-fpm/default.sock` | Faster (no TCP overhead) | nginx + php-fpm on same server |
| TCP socket | `127.0.0.1:9000` | Slightly slower | Across different servers |

Unix sockets are faster because they bypass the network stack entirely — communication happens through the filesystem. This is the preferred method when nginx and php-fpm run on the same host.

### PHP-FPM Pool Configuration

php-fpm organizes worker processes into **pools**. Each pool has its own config in `/etc/php-fpm.d/`.

Key directives in a pool config:

```ini
[default]                              ; Pool name
listen = /var/run/php-fpm/default.sock ; Where to listen
listen.owner = nginx                   ; Socket file owner
listen.group = nginx                   ; Socket file group
listen.mode = 0660                     ; Socket permissions
user = nginx                           ; Process runs as this user
group = nginx                          ; Process group
```

**Why socket ownership matters:** The Unix socket is a file on the filesystem. nginx (running as the `nginx` user) must have read/write permission on that socket file. Setting `listen.owner = nginx` and `listen.group = nginx` ensures nginx can connect.

### nginx FastCGI Configuration

```nginx
location ~ \.php$ {
    fastcgi_pass   unix:/var/run/php-fpm/default.sock;  # Send to socket
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include        fastcgi_params;                       # Standard FastCGI params
}
```

`SCRIPT_FILENAME` is the most critical parameter — it tells php-fpm the full filesystem path of the PHP file to execute. Without it, php-fpm doesn't know which file to run.

> **Real-world context:** nginx + php-fpm is the dominant PHP stack in production. WordPress, Laravel, Symfony, Drupal, Magento — they all run on this pattern. Understanding the socket handoff between nginx and php-fpm, and how to configure pool ownership and fastcgi params, is a core skill for any DevOps engineer supporting PHP applications. This same architecture is what AWS Elastic Beanstalk, Forge, and most managed PHP hosting services implement under the hood.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 1 (`stapp01`) |
| User | tony |
| nginx port | `8098` |
| Document root | `/var/www/html` |
| PHP version | `8.2` |
| Socket path | `/var/run/php-fpm/default.sock` |
| Pool name | `default` |
| Pool config | `/etc/php-fpm.d/www.conf` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 1

```bash
ssh tony@stapp01
```

### Step 2: Install nginx

```bash
sudo yum install -y nginx
```

### Step 3: Install PHP 8.2 via Remi repository

```bash
# EPEL repository (prerequisite)
sudo yum install -y epel-release

# Remi repository for PHP 8.2
sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm

# Reset and enable PHP 8.2 module stream
sudo yum module reset php -y
sudo yum module enable php:remi-8.2 -y

# Install php-fpm and cli
sudo yum install -y php-fpm php-cli
```

### Step 4: Verify PHP version

```bash
php -v
# Expected: PHP 8.2.x (cli)
```

### Step 5: Create socket parent directory

```bash
sudo mkdir -p /var/run/php-fpm
```

### Step 6: Configure PHP-FPM pool

```bash
sudo vi /etc/php-fpm.d/www.conf
```

Apply these changes:

```bash
# Change pool name from [www] to [default]
sudo sed -i 's/^\[www\]/[default]/' /etc/php-fpm.d/www.conf

# Set Unix socket path
sudo sed -i 's|^listen = .*|listen = /var/run/php-fpm/default.sock|' /etc/php-fpm.d/www.conf

# Set socket ownership for nginx access
sudo sed -i 's/^;listen.owner = .*/listen.owner = nginx/' /etc/php-fpm.d/www.conf
sudo sed -i 's/^;listen.group = .*/listen.group = nginx/' /etc/php-fpm.d/www.conf
sudo sed -i 's/^;listen.mode = .*/listen.mode = 0660/' /etc/php-fpm.d/www.conf

# Set process user/group to nginx
sudo sed -i 's/^user = .*/user = nginx/' /etc/php-fpm.d/www.conf
sudo sed -i 's/^group = .*/group = nginx/' /etc/php-fpm.d/www.conf
```

**Verify key settings:**
```bash
grep -E "^\[|^listen|^user|^group" /etc/php-fpm.d/www.conf
```

**Expected output:**
```
[default]
user = nginx
group = nginx
listen = /var/run/php-fpm/default.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0660
```

### Step 7: Start php-fpm and verify socket creation

```bash
sudo systemctl start php-fpm
sudo systemctl enable php-fpm

# Confirm socket was created at the correct path
ls -la /var/run/php-fpm/default.sock
```

**Expected:**
```
srw-rw---- 1 nginx nginx ... /var/run/php-fpm/default.sock
```

`s` = socket file type, owned by `nginx:nginx` ✅

### Step 8: Configure nginx

```bash
sudo vi /etc/nginx/nginx.conf
```

Add inside the `http {}` block:

```nginx
server {
    listen       8098;
    server_name  stapp01;
    root         /var/www/html;
    index        index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass   unix:/var/run/php-fpm/default.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }
}
```

### Step 9: Allow port 8098 in SELinux

```bash
sudo semanage port -a -t http_port_t -p tcp 8098
```

### Step 10: Allow nginx → php-fpm socket connection in SELinux

```bash
sudo setsebool -P httpd_can_network_connect 1
```

### Step 11: Validate nginx config

```bash
sudo nginx -t
# Expected: syntax is ok / test is successful
```

### Step 12: Start nginx

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Step 13: Verify both services are running

```bash
sudo systemctl status nginx
sudo systemctl status php-fpm
sudo ss -tlnp | grep 8098
```

### Step 14: Test from jump host

```bash
curl http://stapp01:8098/index.php
```

**Expected:** PHP application response — not a file download, not a 502 error. ✅

---

## 📌 Commands Reference

```bash
# ─── PHP 8.2 Installation ────────────────────────────────
sudo yum install -y epel-release
sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo yum module reset php -y
sudo yum module enable php:remi-8.2 -y
sudo yum install -y php-fpm php-cli
php -v

# ─── PHP-FPM Pool Config ─────────────────────────────────
sudo mkdir -p /var/run/php-fpm
sudo sed -i 's/^\[www\]/[default]/' /etc/php-fpm.d/www.conf
sudo sed -i 's|^listen = .*|listen = /var/run/php-fpm/default.sock|' /etc/php-fpm.d/www.conf
sudo sed -i 's/^user = .*/user = nginx/' /etc/php-fpm.d/www.conf
sudo sed -i 's/^group = .*/group = nginx/' /etc/php-fpm.d/www.conf

# ─── nginx Config ────────────────────────────────────────
sudo vi /etc/nginx/nginx.conf    # Add server block with fastcgi_pass
sudo nginx -t                    # Validate

# ─── SELinux ─────────────────────────────────────────────
sudo semanage port -a -t http_port_t -p tcp 8098
sudo setsebool -P httpd_can_network_connect 1

# ─── Service Management ──────────────────────────────────
sudo systemctl start php-fpm && sudo systemctl enable php-fpm
sudo systemctl start nginx && sudo systemctl enable nginx

# ─── Verification ────────────────────────────────────────
ls -la /var/run/php-fpm/default.sock     # Socket created + nginx owns it
sudo ss -tlnp | grep 8098                # nginx listening
curl http://stapp01:8098/index.php       # PHP response

# ─── Debugging ───────────────────────────────────────────
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/php-fpm/error.log
sudo journalctl -u php-fpm -n 30
```

---

## ⚠️ Common Mistakes to Avoid

1. **Socket ownership mismatch** — If `listen.owner` is `apache` but nginx runs as `nginx`, nginx gets permission denied on the socket. Always match socket owner to the nginx process user.
2. **Missing `SCRIPT_FILENAME` in fastcgi_params** — This is the most common cause of blank PHP responses or 404s from php-fpm. nginx's default `fastcgi_params` file doesn't include it — it must be explicitly set.
3. **Pool name still `[www]`** — The task requires pool name `default`. The socket path includes the pool name concept — verify with `grep "^\[" /etc/php-fpm.d/www.conf`.
4. **Forgetting `setsebool httpd_can_network_connect`** — On SELinux enforcing systems, nginx is blocked from connecting to local sockets/ports by default. This boolean must be enabled.
5. **Starting nginx before php-fpm** — The socket must exist before nginx tries to connect to it. Always start php-fpm first.
6. **Not creating `/var/run/php-fpm/` directory** — php-fpm won't create parent directories automatically. `mkdir -p /var/run/php-fpm` must be done before starting the service.

---

## 🔍 Troubleshooting — Common Error Scenarios

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `502 Bad Gateway` | Socket doesn't exist or wrong path | Check `ls /var/run/php-fpm/default.sock` |
| `502 Bad Gateway` | SELinux blocking nginx→socket | `setsebool -P httpd_can_network_connect 1` |
| `403 Forbidden` | Wrong document root or permissions | Check `root` in nginx config matches `/var/www/html` |
| PHP shown as plain text | Missing `location ~ \.php$` block | Add fastcgi block to nginx config |
| `connect() to unix socket failed (13: Permission denied)` | Socket ownership wrong | Fix `listen.owner`/`listen.group` in www.conf |

---

## 🔗 References

- [nginx FastCGI Configuration](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)
- [PHP-FPM Configuration Reference](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Remi Repository — PHP 8.2](https://rpms.remirepo.net/)
- [nginx + php-fpm — DigitalOcean Guide](https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-on-centos-8)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
