# Day 15 — Nginx Installation, SSL Certificate Deployment & HTTPS Configuration

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Web Server / SSL/TLS / nginx  
**Difficulty:** Intermediate  
**Status:** ✅ Completed  
**Phase:** 🏁 Phase 1 Complete — Linux Fundamentals

---

## 📋 Task Summary

Deploy and configure **nginx** on App Server 2 (`stapp02`) as a production-ready HTTPS server:

1. Install nginx
2. Move SSL certificate and key from `/tmp/` to a secure system location
3. Configure nginx to serve HTTPS using the provided self-signed certificate
4. Create `index.html` with content `Welcome!` under nginx document root
5. Validate: `curl -Ik https://stapp02/`

---

## 🧠 Concept — nginx, SSL/TLS, and Certificate Deployment

### nginx vs Apache

| Feature | nginx | Apache (httpd) |
|---------|-------|---------------|
| Architecture | Event-driven, async | Process/thread per request |
| Performance | Excellent for static files + reverse proxy | Strong for dynamic content |
| Config style | Block-based (`server {}`) | Directive-based (`.htaccess`) |
| SSL config | `ssl_certificate` / `ssl_certificate_key` | `SSLCertificateFile` / `SSLCertificateKeyFile` |
| Default port | 80 / 443 | 80 / 443 |

nginx is the dominant choice for reverse proxies, load balancers, and high-traffic static file serving in modern infrastructure.

### SSL Certificate Files — What They Are

| File | Purpose | Permissions |
|------|---------|-------------|
| `nautilus.crt` | Public certificate — sent to clients | `644` (readable) |
| `nautilus.key` | Private key — stays on the server | `600` (owner-read only) |

The private key is the most sensitive file on the server. If it leaks, the certificate is compromised. `chmod 600` ensures only root can read it — no other user, no group access.

### Where Certificates Should Live

| Location | Use |
|----------|-----|
| `/etc/nginx/ssl/` | nginx-specific certs (simple setups) |
| `/etc/pki/nginx/` | RHEL/CentOS standard cert location |
| `/etc/ssl/certs/` | Debian/Ubuntu standard |

For this task, `/etc/nginx/ssl/` is clean, nginx-specific, and clearly communicates intent.

### nginx SSL Server Block Structure

```nginx
server {
    listen       443 ssl;           # Listen on HTTPS port
    server_name  stapp02;           # Hostname

    ssl_certificate     /etc/nginx/ssl/nautilus.crt;   # Public cert
    ssl_certificate_key /etc/nginx/ssl/nautilus.key;   # Private key

    root   /usr/share/nginx/html;   # Document root
    index  index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### What `curl -Ik https://stapp02/` Does

```
curl -Ik https://stapp02/
      │└── Show response headers only (no body)
      └─── Ignore SSL certificate verification
           (required for self-signed certs — not trusted by a CA)
```

The `-k` flag is essential for self-signed certificates. Without it, curl refuses the connection because the cert isn't signed by a trusted Certificate Authority.

> **Real-world context:** SSL certificate deployment is a daily task in DevOps — whether deploying certs from Let's Encrypt, internal PKI, or commercial CAs. The pattern is always the same: place the cert and key in a secure location with correct permissions, reference them in the server config, validate syntax, restart the service. Understanding this on nginx prepares you directly for AWS ACM, Kubernetes TLS secrets, and cert-manager.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 2 (`stapp02`) |
| User | steve |
| Cert source | `/tmp/nautilus.crt` |
| Key source | `/tmp/nautilus.key` |
| Cert destination | `/etc/nginx/ssl/` |
| Document root | `/usr/share/nginx/html/` |
| Config file | `/etc/nginx/nginx.conf` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 2

```bash
ssh steve@stapp02
```

### Step 2: Install nginx

```bash
sudo yum install -y nginx
```

### Step 3: Create SSL directory and move certificates

```bash
# Create secure directory for certs
sudo mkdir -p /etc/nginx/ssl

# Move certs from /tmp to proper location
sudo mv /tmp/nautilus.crt /etc/nginx/ssl/
sudo mv /tmp/nautilus.key /etc/nginx/ssl/

# Set correct permissions
sudo chmod 600 /etc/nginx/ssl/nautilus.key   # Private key — owner read only
sudo chmod 644 /etc/nginx/ssl/nautilus.crt   # Certificate — readable
```

### Step 4: Fix SELinux context on certificate files

```bash
sudo restorecon -Rv /etc/nginx/ssl/
```

Without correct SELinux labels, nginx can't read the cert files even with correct filesystem permissions.

### Step 5: Create index.html under document root

```bash
echo "Welcome!" | sudo tee /usr/share/nginx/html/index.html
```

**Verify:**
```bash
cat /usr/share/nginx/html/index.html
# Expected: Welcome!
```

### Step 6: Configure nginx with SSL

Edit `/etc/nginx/nginx.conf` and add/update the HTTPS server block:

```bash
sudo vi /etc/nginx/nginx.conf
```

Add inside the `http {}` block:

```nginx
server {
    listen       443 ssl;
    server_name  stapp02;

    ssl_certificate     /etc/nginx/ssl/nautilus.crt;
    ssl_certificate_key /etc/nginx/ssl/nautilus.key;

    root   /usr/share/nginx/html;
    index  index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Step 7: Validate nginx configuration syntax

```bash
sudo nginx -t
```

**Expected output:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Never skip this. A config error on restart brings the whole server down.

### Step 8: Start and enable nginx

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Step 9: Verify nginx is running and listening on 443

```bash
sudo systemctl status nginx
sudo ss -tlnp | grep nginx
# Expected: LISTEN on *:443
```

### Step 10: Test from jump host

```bash
curl -Ik https://stapp02/
```

**Expected output:**
```
HTTP/1.1 200 OK
Server: nginx/x.xx.x
Date: ...
Content-Type: text/html
Content-Length: 9
```

✅ nginx is serving HTTPS with the deployed SSL certificate.

---

## 📌 Commands Reference

```bash
# ─── Installation ────────────────────────────────────────
sudo yum install -y nginx

# ─── Certificate Deployment ──────────────────────────────
sudo mkdir -p /etc/nginx/ssl
sudo mv /tmp/nautilus.crt /etc/nginx/ssl/
sudo mv /tmp/nautilus.key /etc/nginx/ssl/
sudo chmod 600 /etc/nginx/ssl/nautilus.key
sudo chmod 644 /etc/nginx/ssl/nautilus.crt
sudo restorecon -Rv /etc/nginx/ssl/

# ─── Content ─────────────────────────────────────────────
echo "Welcome!" | sudo tee /usr/share/nginx/html/index.html

# ─── Config Validation ───────────────────────────────────
sudo nginx -t                              # Always before restart

# ─── Service Management ──────────────────────────────────
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
sudo systemctl reload nginx               # Reload config without downtime

# ─── Verification ────────────────────────────────────────
sudo ss -tlnp | grep nginx                # Port 443 bound
curl -Ik https://stapp02/                 # From jump host
curl -Ik --resolve stapp02:443:IP https://stapp02/  # Force IP resolution

# ─── Debugging ───────────────────────────────────────────
sudo nginx -t                             # Config syntax
sudo tail -f /var/log/nginx/error.log     # Error log
sudo tail -f /var/log/nginx/access.log    # Access log
sudo journalctl -u nginx -n 30 --no-pager # systemd journal
```

---

## ⚠️ Common Mistakes to Avoid

1. **Leaving certs in `/tmp/`** — `/tmp/` is world-readable and cleared on reboots. Certs must live in a protected directory like `/etc/nginx/ssl/` with restricted permissions.
2. **Wrong key permissions** — `nautilus.key` must be `600`. nginx will refuse to start if the private key is group or world readable — it's a deliberate security check.
3. **Skipping `nginx -t`** — One malformed bracket in `nginx.conf` brings the entire server down on restart. Always validate first.
4. **Missing `restorecon`** — On SELinux enforcing systems, moved files retain the SELinux label of their original location (`/tmp/`). nginx can't read a file labelled as `tmp_t`. `restorecon` corrects the label to `cert_t`.
5. **Forgetting `-k` in curl** — Self-signed certs aren't trusted by curl's CA bundle. Without `-k`, curl refuses the connection. This is expected and correct — it's not a failure.
6. **Not enabling nginx** — `systemctl start` brings it up now. `systemctl enable` makes it survive reboots.

---

## 🔍 SSL/TLS Configuration Quality Reference

For production servers, additional hardening beyond the basics:

```nginx
server {
    listen 443 ssl;
    server_name stapp02;

    # Certificate files
    ssl_certificate     /etc/nginx/ssl/nautilus.crt;
    ssl_certificate_key /etc/nginx/ssl/nautilus.key;

    # Protocol hardening — disable old/vulnerable versions
    ssl_protocols TLSv1.2 TLSv1.3;

    # Strong cipher suites only
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    # HSTS — force HTTPS for future visits
    add_header Strict-Transport-Security "max-age=63072000" always;

    root  /usr/share/nginx/html;
    index index.html;
}
```

> This is the Mozilla SSL Configuration Generator recommended baseline for modern nginx.

---

## 🔗 References

- [nginx SSL Termination Guide](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [Mozilla SSL Config Generator](https://ssl-config.mozilla.org/)
- [nginx Configuration Reference](https://nginx.org/en/docs/ngx_http_core_module.html)
- [SELinux — File Context Management](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: `curl https://stapp02/` fails with "SSL certificate problem: self signed certificate". How do you test it anyway, and what does this mean in production?**

```bash
# For testing self-signed certs:
curl -k https://stapp02/         # -k = ignore cert verification
curl --insecure https://stapp02/

# In production: this error means the certificate is NOT trusted by a CA
# Solutions:
# 1. Use Let's Encrypt (free, auto-renewed, trusted):
sudo certbot --nginx -d yourdomain.com

# 2. Use an internal CA cert and distribute it to clients:
sudo cp internal-ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust

# 3. For testing only: use -k (never in production automation)
```

> Self-signed certs are fine for internal services where you control all clients. For anything internet-facing or where clients aren't under your control, use Let's Encrypt or a commercial CA.

---

**Q2: nginx fails to start after adding SSL config. What do you check first?**

```bash
# Config syntax check — always first
sudo nginx -t

# Common errors and fixes:
# "PEM_read_bio_X509_AUX() failed" → wrong cert file path or corrupt cert
# "SSL_CTX_use_PrivateKey_file() failed" → key path wrong or permissions
# "key values mismatch" → cert and key are from different pairs

# Check certificate permissions
ls -la /etc/nginx/ssl/
# nautilus.key must be 600 — not 644 or 640

# Verify cert/key match:
openssl x509 -noout -modulus -in nautilus.crt | md5sum
openssl rsa  -noout -modulus -in nautilus.key | md5sum
# Hashes must match — if different, wrong key for this cert
```

---

**Q3: Why must the private key be `chmod 600` and not `644`?**

> The private key is the most sensitive file on the server. If it has `644` (world-readable), any user on the system can read it, copy it, and use it to impersonate your server.
>
> nginx actually enforces this: on some configurations it will refuse to start if the private key has group or world read permissions. `600` means only the owner (root) can read it. nginx, running as root at startup, reads the key once and then drops privileges.

---

**Q4: After moving certs from `/tmp/` to `/etc/nginx/ssl/`, nginx returns 403 or can't read the files. What's the SELinux issue?**

```bash
# Files moved from /tmp/ keep tmp_t SELinux label
ls -Z /etc/nginx/ssl/
# system_u:object_r:tmp_t:s0  nautilus.crt  ← wrong label

# Fix: restore correct context
sudo restorecon -Rv /etc/nginx/ssl/
# system_u:object_r:cert_t:s0  nautilus.crt  ✅

# Verify
ls -Z /etc/nginx/ssl/
```

> `tmp_t` files are inaccessible to nginx's `httpd_t` process. `restorecon` relabels them with the correct `cert_t` context. This is always required when moving files from `/tmp/` to system directories on SELinux-enforcing systems.

---

**Q5: What additional SSL hardening would you add in a production nginx config beyond the basics?**

```nginx
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate     /etc/nginx/ssl/cert.crt;
    ssl_certificate_key /etc/nginx/ssl/cert.key;

    # Only modern TLS versions
    ssl_protocols TLSv1.2 TLSv1.3;

    # Strong cipher suites (ECDHE preferred)
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    # HSTS: force HTTPS for 2 years, include subdomains
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;

    # Prevent clickjacking
    add_header X-Frame-Options DENY;

    # Enable OCSP stapling (faster cert validation for clients)
    ssl_stapling on;
    ssl_stapling_verify on;
}
```

> These are the Mozilla SSL Configuration Generator "modern" recommendations. In practice, the TLS protocol restriction and HSTS header are the most impactful additions after the basic cert setup.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
