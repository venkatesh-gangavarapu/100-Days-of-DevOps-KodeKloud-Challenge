# Day 42 — Creating a Custom Docker Bridge Network with Subnet Configuration

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker / Networking  
**Difficulty:** Beginner–Intermediate  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

On **App Server 2** (`stapp02`), create a custom Docker network:

- Network name: `ecommerce`
- Driver: `bridge`
- Subnet: `172.28.0.0/24`
- IP range: `172.28.0.0/24`

---

## 🧠 Concept — Docker Networking

### Docker Network Drivers

| Driver | Description | Use Case |
|--------|-------------|---------|
| **bridge** | Default — isolated network on single host | Most container deployments |
| **host** | Container shares host network stack | High-performance, no isolation |
| **none** | No networking | Completely isolated containers |
| **overlay** | Multi-host networking | Docker Swarm / distributed apps |
| **macvlan** | Assign MAC address to container | Legacy apps needing direct network access |

### Default Bridge vs Custom Bridge

| Feature | Default `bridge` | Custom bridge |
|---------|-----------------|---------------|
| DNS resolution | ❌ By IP only | ✅ By container name |
| Isolation | Shared with all containers | Only containers you attach |
| Subnet control | Docker-assigned | ✅ You define it |
| Better for production | ❌ | ✅ |

### Subnet vs IP Range

```
Subnet:   172.28.0.0/24  → Defines the full network range (172.28.0.0 - 172.28.0.255)
IP Range: 172.28.0.0/24  → Defines which IPs Docker assigns to containers

When IP range is a subset of subnet:
Subnet:   172.28.0.0/24   → Full network (256 addresses)
IP Range: 172.28.0.128/25 → Docker only assigns 172.28.0.128 - 172.28.0.255
                             (.0-.127 reserved for other uses like static IPs)
```

In this task both are `172.28.0.0/24` — Docker uses the entire subnet for container IPs.

> **Real-world context:** Custom Docker networks are the standard in production multi-container deployments. They provide DNS-based service discovery (containers reach each other by name, not IP), network isolation between application stacks, and predictable IP addressing. Every Docker Compose deployment creates a custom network automatically. Defining subnets explicitly prevents IP conflicts in environments with multiple Docker networks or VPN overlaps.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 2 (`stapp02`) |
| User | steve |
| Network name | `ecommerce` |
| Driver | `bridge` |
| Subnet | `172.28.0.0/24` |
| IP range | `172.28.0.0/24` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 2

```bash
ssh steve@stapp02
```

### Step 2: Create the custom bridge network

```bash
sudo docker network create \
  --driver bridge \
  --subnet 172.28.0.0/24 \
  --ip-range 172.28.0.0/24 \
  ecommerce
```

**Expected output:**
```
abc123def456789...   ← network ID
```

### Step 3: Verify the network was created correctly

```bash
sudo docker network inspect ecommerce
```

**Expected output (key fields):**
```json
[
    {
        "Name": "ecommerce",
        "Driver": "bridge",
        "IPAM": {
            "Driver": "default",
            "Config": [
                {
                    "Subnet": "172.28.0.0/24",
                    "IPRange": "172.28.0.0/24"
                }
            ]
        }
    }
]
```

✅ All three requirements confirmed: bridge driver, correct subnet, correct IP range.

### Step 4: List all networks to confirm

```bash
sudo docker network ls
```

**Expected:**
```
NETWORK ID     NAME        DRIVER    SCOPE
...            bridge      bridge    local
...            ecommerce   bridge    local   ← our network
...            host        host      local
...            none        null      local
```

---

## 📌 Commands Reference

```bash
# ─── Create network ──────────────────────────────────────
sudo docker network create \
  --driver bridge \
  --subnet 172.28.0.0/24 \
  --ip-range 172.28.0.0/24 \
  ecommerce

# ─── Inspect ─────────────────────────────────────────────
sudo docker network inspect ecommerce
sudo docker network ls

# ─── Connect containers to network ───────────────────────
docker run -d --network ecommerce --name web nginx:alpine
docker run -d --network ecommerce --name db postgres:15

# ─── Connect existing container to network ───────────────
docker network connect ecommerce existing_container

# ─── Disconnect container from network ───────────────────
docker network disconnect ecommerce container_name

# ─── Remove network ──────────────────────────────────────
docker network rm ecommerce           # Only works if no containers attached
docker network prune                  # Remove all unused networks
```

---

## ⚠️ Common Mistakes to Avoid

1. **Subnet conflict with host or existing Docker networks** — Always check existing network ranges with `docker network ls` and `ip route` before creating. Overlapping subnets cause routing conflicts.
2. **IP range outside the subnet** — The `--ip-range` must be a subset of `--subnet`. `--subnet 172.28.0.0/24` with `--ip-range 172.29.0.0/24` fails because the IP range is outside the subnet.
3. **Trying to remove a network with active containers** — `docker network rm` fails if any containers are connected. Disconnect all containers first or use `docker network prune` for cleanup.
4. **Using the default bridge for production** — The default bridge doesn't support DNS container name resolution. Always create a custom bridge network for applications that need containers to communicate by service name.

---

## 🔍 How Docker Bridge Networking Works

```
Host machine
├── docker0 (default bridge: 172.17.0.0/16)
│   ├── container_a: 172.17.0.2
│   └── container_b: 172.17.0.3
│
└── br-abc123 (ecommerce bridge: 172.28.0.0/24)
    ├── web: 172.28.0.2     ← containers on ecommerce network
    └── db:  172.28.0.3     ← can reach each other by name
```

Each custom bridge network gets its own Linux bridge interface on the host. Containers on the same custom bridge can communicate using container names as DNS hostnames.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between the default Docker bridge network and a custom bridge network?**

The default `bridge` network connects all containers on the same host but provides no DNS-based name resolution — containers must communicate using IP addresses. Custom bridge networks add automatic DNS resolution: containers on the same custom network can reach each other using container names as hostnames (`web`, `db`, `redis`). Custom networks also provide better isolation — only containers explicitly attached to the network can communicate, unlike the default bridge where all containers share the same space. For any production deployment with multiple containers, custom networks are the correct choice.

---

**Q2: What does `--ip-range` do when it's different from `--subnet`?**

`--subnet` defines the entire address space for the network. `--ip-range` defines the subset of that space that Docker's IPAM (IP Address Management) uses when automatically assigning container IPs. If you set `--subnet 172.28.0.0/24` and `--ip-range 172.28.0.128/25`, Docker auto-assigns IPs from 172.28.0.128 to 172.28.0.255. The range 172.28.0.0 to 172.28.0.127 is still part of the network but Docker won't auto-assign those IPs — they're available for manually assigned static IPs using `--ip` in `docker run`. This pattern is used when you need some containers with predictable static IPs alongside others with dynamic assignment.

---

**Q3: How do containers on different Docker networks communicate with each other?**

By default they can't — Docker network isolation prevents cross-network communication. To allow two containers on different networks to communicate, connect one container to both networks: `docker network connect second_network container_name`. Now that container has interfaces on both networks and can route between them. Alternatively, use host networking (`--network host`) which bypasses network isolation entirely, or use a reverse proxy container that bridges the networks. In practice, well-designed microservice architectures use network segmentation deliberately — frontend containers share one network, backend services share another, and only specific containers bridge them.

---

**Q4: What is Docker's IPAM and why does it matter?**

IPAM (IP Address Management) is Docker's system for automatically assigning IP addresses to containers within a network. When you create a network with `--subnet` and `--ip-range`, you're configuring the IPAM driver's address pool. Docker uses this to assign unique IPs to containers as they join the network and reclaim IPs when containers leave. Without explicit subnet configuration, Docker auto-assigns from its internal ranges (typically 172.17.0.0/16 for bridge, 172.18.0.0/16 for the next, etc.). Explicit subnet configuration matters in environments with VPNs, on-premises networks, or cloud VPCs where Docker's auto-assigned ranges might conflict with existing network infrastructure.

---

**Q5: How does Docker networking relate to Kubernetes networking?**

Docker networking is conceptually the foundation for understanding Kubernetes networking, but Kubernetes implements its own networking model (CNI — Container Network Interface). In Kubernetes, every Pod gets a unique IP address, Pods can communicate with any other Pod across nodes without NAT, and Services provide stable virtual IPs for Pod groups. Kubernetes uses CNI plugins (Calico, Flannel, Weave, Cilium) instead of Docker's bridge driver. Understanding Docker bridge networking — subnets, IP ranges, DNS resolution — directly transfers to understanding Kubernetes network concepts like ClusterIP, NodePort, and Pod network CIDRs.

---

**Q6: How do you assign a static IP to a Docker container?**

Use `docker run --network ecommerce --ip 172.28.0.10 --name web nginx`. The static IP must be within the network's subnet but outside the `--ip-range` (which is reserved for dynamic assignment). If the IP range covers the entire subnet as in today's task (`172.28.0.0/24`), Docker may conflict with your static IP request. Best practice: define a smaller `--ip-range` (e.g., `172.28.0.128/25`) within a larger subnet, keeping the lower range (`172.28.0.1` to `172.28.0.127`) available for static assignments. Static IPs are useful for containers that other systems need to reach at a predictable address — database servers, monitoring agents, internal API gateways.

---

## 🔗 References

- [`docker network create` documentation](https://docs.docker.com/engine/reference/commandline/network_create/)
- [Docker Network Drivers](https://docs.docker.com/network/)
- [Docker Bridge Networking](https://docs.docker.com/network/bridge/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
