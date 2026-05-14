# Day 58 — Deploying Grafana on Kubernetes with NodePort Service

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Monitoring / Real-World Tools  
**Difficulty:** Intermediate  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

Deploy Grafana on Kubernetes and expose it externally:

1. **Deployment** `grafana-deployment-nautilus` — `grafana/grafana:latest`, 1 replica
2. **Service** `grafana-service-nautilus` — NodePort type, nodePort `32000`

Access the Grafana login page at `http://<node-ip>:32000`

---

## 🧠 Concept — Deploying Real-World Tools on Kubernetes

### What is Grafana?

Grafana is an open-source observability platform for metrics visualization and analytics. It connects to data sources like Prometheus, InfluxDB, CloudWatch, and Loki, and renders dashboards from that data.

```
Data Sources → Grafana → Dashboards
(Prometheus,     │         (CPU usage, error rates,
 CloudWatch,     │          latency, business metrics)
 InfluxDB)       └── Port 3000 (default)
```

### The Grafana Image

`grafana/grafana:latest` is the official Grafana image from Docker Hub. Grafana runs its web UI on **port 3000** by default — this drives all port configuration in the manifest.

### Port Mapping for Grafana

```
nodePort: 32000    ← external access
port: 3000         ← Service cluster-internal port
targetPort: 3000   ← Grafana container port (hardcoded in app)
```

All three must reference 3000 for the container side — Grafana doesn't listen on 80.

> **Real-world context:** Grafana + Prometheus is the standard observability stack for Kubernetes clusters. Every cloud-native infrastructure team deploys Grafana for monitoring. Understanding how to deploy, expose, and eventually configure Grafana with data sources is a foundational SRE and DevOps skill. In production, Grafana is typically deployed via the official Helm chart with PersistentVolumeClaims for dashboard storage.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Deployment | `grafana-deployment-nautilus` |
| Image | `grafana/grafana:latest` |
| Container port | `3000` |
| Service | `grafana-service-nautilus` |
| Service type | `NodePort` |
| nodePort | `32000` |
| Default credentials | `admin` / `admin` |

---

## 🔧 The Manifests

### grafana-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-deployment-nautilus
  labels:
    app: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
        - name: grafana-container
          image: grafana/grafana:latest
          ports:
            - containerPort: 3000
```

### grafana-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: grafana-service-nautilus
spec:
  type: NodePort
  selector:
    app: grafana
  ports:
    - port: 3000
      targetPort: 3000
      nodePort: 32000
```

---

## 🔧 Solution — Step by Step

### Step 1: Apply both manifests

```bash
kubectl apply -f grafana-deployment.yaml
kubectl apply -f grafana-service.yaml
```

### Step 2: Verify Deployment

```bash
kubectl get deployment grafana-deployment-nautilus
# NAME                          READY   UP-TO-DATE   AVAILABLE
# grafana-deployment-nautilus   1/1     1            1         ✅
```

### Step 3: Verify Pod

```bash
kubectl get pods -l app=grafana
# Running ✅
```

### Step 4: Verify Service

```bash
kubectl get service grafana-service-nautilus
# TYPE: NodePort   PORT(S): 3000:32000/TCP ✅
```

### Step 5: Verify endpoints

```bash
kubectl get endpoints grafana-service-nautilus
# Pod IP listed — Service connected ✅
```

### Step 6: Access Grafana login page

```bash
curl -s http://localhost:32000 | grep -i "grafana"
```

Or open `http://<node-ip>:32000` in browser.

**Default login:** `admin` / `admin` ✅

---

## 📌 Commands Reference

```bash
kubectl apply -f grafana-deployment.yaml
kubectl apply -f grafana-service.yaml
kubectl get deployment grafana-deployment-nautilus
kubectl get pods -l app=grafana
kubectl get service grafana-service-nautilus
kubectl get endpoints grafana-service-nautilus
kubectl logs -l app=grafana
curl http://localhost:32000
kubectl delete deployment grafana-deployment-nautilus
kubectl delete service grafana-service-nautilus
```

---

## ⚠️ Common Mistakes to Avoid

1. **Using port 80 instead of 3000** — Grafana listens on port 3000 by default. Setting `targetPort: 80` means traffic hits a port where nothing is listening — connection refused.
2. **Label mismatch** — Service `selector: app: grafana` must match Deployment Pod template `labels: app: grafana` exactly.
3. **Not waiting for Pod to be Ready** — Grafana takes a few seconds to initialize. The login page is only accessible once the Pod is in `Running` state with `1/1` Ready.
4. **Accessing before endpoints are registered** — Check `kubectl get endpoints` before testing. No endpoints = Service not connected to Pod.

---

## 🔍 Production Grafana Architecture

```
Current (lab):                    Production:
grafana:latest → emptyDir         grafana:latest → PersistentVolumeClaim
(dashboards lost on restart)      (dashboards persist across restarts)

NodePort:32000                    LoadBalancer or Ingress
(direct node IP access)           (domain name, SSL termination)

No auth config                    LDAP/OAuth integration
(admin/admin)                     (SSO with corporate identity)
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is Grafana and what role does it play in a Kubernetes observability stack?**

Grafana is a visualization and analytics platform that connects to time-series databases and metrics backends to display dashboards. In Kubernetes observability, the standard stack is Prometheus (metrics collection and storage) + Grafana (visualization). Prometheus scrapes metrics from Kubernetes nodes, Pods, and applications. Grafana queries Prometheus and renders graphs, heatmaps, and alerts. The kube-prometheus-stack Helm chart deploys both together with pre-built Kubernetes dashboards. Grafana also integrates with Loki (log aggregation) and Tempo (distributed tracing) for full observability — the LGTM stack (Loki, Grafana, Tempo, Mimir).

---

**Q2: How would you persist Grafana dashboards and data sources across Pod restarts?**

By default, Grafana stores dashboards and configuration in an SQLite database inside the container — lost when the Pod restarts. Production setup: create a PersistentVolumeClaim and mount it at `/var/lib/grafana`. This stores the SQLite database (or PostgreSQL/MySQL for HA) on persistent storage. For dashboard-as-code, use Grafana's provisioning feature — mount ConfigMaps containing dashboard JSON and datasource YAML at `/etc/grafana/provisioning/`. Dashboards are loaded from files at startup, survive Pod recreation, and can be version-controlled in Git.

---

**Q3: What is the Grafana/Prometheus stack and how do they work together?**

Prometheus is a pull-based metrics system — it scrapes metrics endpoints (`/metrics`) exposed by applications and Kubernetes components on a schedule, storing them as time-series data. Grafana connects to Prometheus as a data source and allows you to write PromQL queries to extract and visualize that data. Example: a PromQL query `rate(http_requests_total[5m])` shows request rate over 5 minutes, rendered as a line chart in Grafana. Kubernetes exposes metrics via kube-state-metrics and node-exporter; these are scraped by Prometheus and visualized in Grafana dashboards. Together they give complete visibility into cluster health, application performance, and business metrics.

---

**Q4: How would you deploy Grafana properly in production using Helm?**

The kube-prometheus-stack Helm chart is the standard approach: `helm install prometheus prometheus-community/kube-prometheus-stack`. It deploys Prometheus Operator, Prometheus, Grafana, AlertManager, kube-state-metrics, and node-exporter with pre-configured dashboards for Kubernetes cluster monitoring. For Grafana specifically: `helm install grafana grafana/grafana --set persistence.enabled=true --set adminPassword=SecurePass123`. Helm manages upgrades, rollbacks, and configuration as code. Values files in Git provide the same GitOps auditability as YAML manifests. This is significantly more maintainable than hand-crafted YAML for complex stateful applications.

---

**Q5: What is an Ingress and how would you use it instead of NodePort for Grafana?**

NodePort exposes a service on a high port (32000) directly on node IPs — not user-friendly for production. An Ingress resource provides HTTP/HTTPS routing via a domain name. With an Ingress controller (nginx-ingress, Traefik) installed, you define rules like "requests to `grafana.company.com` go to `grafana-service:3000`". The Ingress controller handles TLS termination (with cert-manager for auto-renewal), path-based routing, and virtual hosting. Users access `https://grafana.company.com` with a valid SSL cert instead of `http://node-ip:32000`. In cloud environments, the Ingress controller is backed by a LoadBalancer Service which provisions a cloud load balancer automatically.

---

**Q6: How do you secure Grafana in a production Kubernetes deployment?**

Several layers: (1) **Change default credentials** — `admin/admin` is the default. Use a Kubernetes Secret for the admin password rather than a hardcoded value. (2) **Enable HTTPS** — configure TLS via Ingress with cert-manager. (3) **SSO integration** — configure OAuth2 (GitHub, Google, Okta) or LDAP for authentication so users log in with corporate credentials. (4) **RBAC** — configure Grafana's built-in RBAC to assign viewer/editor/admin roles per user or team. (5) **Network Policy** — restrict which Pods can reach Grafana in the cluster. (6) **Secrets management** — store datasource credentials (Prometheus username/password, database credentials) in Kubernetes Secrets, not plaintext ConfigMaps.

---

## 🔗 References

- [Grafana on Docker Hub](https://hub.docker.com/r/grafana/grafana)
- [Grafana Documentation](https://grafana.com/docs/)
- [kube-prometheus-stack Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Grafana Kubernetes Deployment](https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
