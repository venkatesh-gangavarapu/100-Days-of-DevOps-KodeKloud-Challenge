# Day 16 — Configuring nginx as a Load Balancer Across All App Servers

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Load Balancing / nginx / High Availability  
**Difficulty:** Intermediate  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

The Nautilus application was experiencing performance degradation under increasing traffic. The solution: deploy the application on a **high availability stack** using nginx as a load balancer (`stlb01`) distributing traffic across all three app servers (`stapp01`, `stapp02`, `stapp03`).

Requirements:
- Install nginx on LBR server (`stlb01`)
- Configure load balancing using **upstream** in the `http` context
- Modify **only** `/etc/nginx/nginx.conf`
- Do **not** change Apache port on any app server
- Verify: `curl http://stlb01:80`

---

## 🧠 Concept — nginx Load Balancing Architecture

### What a Load Balancer Does

A load balancer sits between clients and backend servers. It receives all incoming requests and distributes them across the server pool — preventing any single server from being overwhelmed.

```
                    ┌─────────────────────┐
    curl            │   nginx LBR         │
  ──────────────►   │   stlb01:80         │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                 ▼
        stapp01:PORT     stapp02:PORT      stapp03:PORT
        (Apache)         (Apache)          (Apache)
```

### nginx Load Balancing Methods

| Method | Directive | Behaviour |
|--------|-----------|-----------|
| **Round Robin** | (default) | Requests distributed sequentially across servers |
| **Least Connections** | `least_conn` | Next request to server with fewest active connections |
| **IP Hash** | `ip_hash` | Client IP determines server — session persistence |
| **Weighted** | `weight=N` | More requests sent to higher-weighted servers |

Round robin (default) is used here — ideal for stateless applications where any server can handle any request.

### nginx `upstream` Block — The Core Concept

```nginx
http {
    upstream nautilus_app {          # Name this pool anything
        server stapp01:PORT;         # Backend server 1
        server stapp02:PORT;         # Backend server 2
        server stapp03:PORT;         # Backend server 3
        # nginx round-robins by default
    }

    server {
        listen 80;                   # LBR listens here

        location / {
            proxy_pass http://nautilus_app;   # Forward to pool
        }
    }
}
```

### Key nginx Proxy Directives

```nginx
proxy_pass          http://upstream_name;    # Forward to upstream pool
proxy_set_header    Host $host;              # Pass original host header
proxy_set_header    X-Real-IP $remote_addr; # Pass client's real IP
proxy_connect_timeout 30s;                  # Connection timeout to backend
proxy_read_timeout  60s;                    # Read timeout from backend
```

> **Real-world context:** nginx as a load balancer is one of the most common infrastructure patterns in existence. AWS ALB, GCP Load Balancing, and Azure Load Balancer all implement the same conceptual model — a frontend listener distributing to a backend pool. Understanding nginx's upstream model directly transfers to understanding every cloud load balancer you'll configure. This is also the foundation for reverse proxies, API gateways, and service mesh ingress controllers.

---

## 🖥️ Environment

| Role | Host | User |
|------|------|------|
| Load Balancer | `stlb01` | loki |
| App Server 1 | `stapp01` | tony |
| App Server 2 | `stapp02` | steve |
| App Server 3 | `stapp03` | banner |

---

## 🔧 Solution — Step by Step

### Phase 1: Recon — Verify App Servers Before Touching LBR

#### Step 1: Check Apache port on all app servers

```bash
# From jump host
for host in stapp01 stapp02 stapp03; do
  echo "=== $host ==="
  ssh $host "grep -i '^Listen' /etc/httpd/conf/httpd.conf"
done
```

Note the port — this is what goes into the upstream block. **Do not change it.**

#### Step 2: Verify Apache is running on all servers

```bash
for host in stapp01 stapp02 stapp03; do
  echo "=== $host ==="
  ssh $host "sudo systemctl status httpd --no-pager | grep Active"
done
```

**If any server has Apache down:**
```bash
ssh tony@stapp01 "sudo systemctl start httpd && sudo systemctl enable httpd"
ssh steve@stapp02 "sudo systemctl start httpd && sudo systemctl enable httpd"
ssh banner@stapp03 "sudo systemctl start httpd && sudo systemctl enable httpd"
```

---

### Phase 2: Configure nginx Load Balancer on stlb01

#### Step 3: SSH into LBR server

```bash
ssh loki@stlb01
```

#### Step 4: Install nginx (if not already present)

```bash
sudo yum install -y nginx
```

#### Step 5: Edit `/etc/nginx/nginx.conf`

```bash
sudo vi /etc/nginx/nginx.conf
```

Add the `upstream` block and `server` block inside the existing `http {}` section:

```nginx
http {

    upstream nautilus_app {
        server stapp01:PORT;
        server stapp02:PORT;
        server stapp03:PORT;
    }

    server {
        listen       80;
        server_name  stlb01;

        location / {
            proxy_pass         http://nautilus_app;
            proxy_set_header   Host              $host;
            proxy_set_header   X-Real-IP         $remote_addr;
            proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        }
    }

    # ... rest of existing config ...
}
```

> Replace `PORT` with the actual Apache port found in Phase 1.

#### Step 6: Validate nginx configuration

```bash
sudo nginx -t
# Expected:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Never skip this. A bad config fails the entire LBR on restart.

#### Step 7: Start and enable nginx

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### Step 8: Verify nginx is running and listening on port 80

```bash
sudo systemctl status nginx
sudo ss -tlnp | grep nginx
# Expected: LISTEN on *:80
```

---

### Phase 3: Verification

#### Step 9: Test from jump host

```bash
curl http://stlb01:80
```

**Expected:** HTML response from one of the app servers — nginx is proxying to the backend pool. ✅

#### Step 10: Confirm round-robin is working

```bash
# Hit the LBR multiple times — responses come from different backends
curl http://stlb01:80
curl http://stlb01:80
curl http://stlb01:80
```

If the app serves any server-identifying content, you'll see it rotate across stapp01, stapp02, stapp03.

---

## 📌 Commands Reference

```bash
# ─── Recon (from jump host) ──────────────────────────────
for host in stapp01 stapp02 stapp03; do
  echo "=== $host ==="
  ssh $host "grep -i '^Listen' /etc/httpd/conf/httpd.conf && \
             sudo systemctl is-active httpd"
done

# ─── LBR Setup ───────────────────────────────────────────
ssh loki@stlb01
sudo yum install -y nginx

# ─── Config Edit ─────────────────────────────────────────
sudo vi /etc/nginx/nginx.conf
# Add upstream block + server block inside http {}

# ─── Validate & Start ────────────────────────────────────
sudo nginx -t                          # Config syntax check
sudo systemctl start nginx
sudo systemctl enable nginx

# ─── Verify ──────────────────────────────────────────────
sudo ss -tlnp | grep :80
curl http://stlb01:80                  # From jump host

# ─── Load Balancing Verification ─────────────────────────
for i in {1..6}; do
  echo -n "Request $i: "
  curl -s http://stlb01:80 | head -1
done

# ─── Debugging ───────────────────────────────────────────
sudo nginx -T                          # Dump full parsed config
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
sudo journalctl -u nginx -n 30 --no-pager
```

---

## ⚠️ Common Mistakes to Avoid

1. **Adding `server {}` outside `http {}`** — As we saw on Day 15, nginx enforces strict block nesting. `upstream {}` and `server {}` must both be inside `http {}`.
2. **Wrong backend port** — The upstream `server stapp01:PORT` must match what Apache is actually listening on. Check with `grep '^Listen' /etc/httpd/conf/httpd.conf` before writing the config.
3. **Modifying Apache config** — The task explicitly prohibits changing the Apache port on app servers. The LBR config adapts to whatever Apache is using.
4. **Editing a virtual host file instead of `nginx.conf`** — The task requires changes to `/etc/nginx/nginx.conf` only. Don't create files in `/etc/nginx/conf.d/`.
5. **Not verifying Apache is up before testing LBR** — If Apache is down on any backend, nginx will return 502 Bad Gateway for requests routed to that server. Always confirm backends are healthy first.
6. **Skipping `nginx -t`** — Always validate before start/restart. Saves you from a config error taking the LBR offline.

---

## 🔍 nginx Load Balancing — Production Enhancements

```nginx
upstream nautilus_app {
    least_conn;                          # Route to least busy server

    server stapp01:PORT weight=3;        # Gets 3x more traffic
    server stapp02:PORT weight=1;
    server stapp03:PORT backup;          # Only used if others fail

    keepalive 32;                        # Persistent connections to backends
}

server {
    listen 80;

    location / {
        proxy_pass          http://nautilus_app;
        proxy_set_header    Host              $host;
        proxy_set_header    X-Real-IP         $remote_addr;
        proxy_set_header    X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_connect_timeout 10s;
        proxy_read_timeout    30s;

        # Health check — mark backend down after 3 failures
        proxy_next_upstream error timeout;
        max_fails=3;
        fail_timeout=30s;
    }
}
```

---

## 🔗 References

- [nginx Load Balancing Guide](https://nginx.org/en/docs/http/load_balancing.html)
- [nginx upstream module](https://nginx.org/en/docs/http/ngx_http_upstream_module.html)
- [nginx proxy_pass directive](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass)
- [nginx HTTP load balancing — DigitalOcean](https://www.digitalocean.com/community/tutorials/understanding-nginx-http-proxying-load-balancing-buffering-and-caching)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
