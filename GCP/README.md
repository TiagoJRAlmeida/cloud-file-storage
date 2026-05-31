# Cloud File Storage System

A Dropbox-like file storage platform built on Kubernetes, deployed on Google Cloud Platform. Exposes a RESTful API for authenticated file upload, download, sharing, and management — backed by S3-compatible object storage and fronted by a hardened NGINX gateway. All infrastructure is provisioned and torn down exclusively via Terraform.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Component Breakdown](#component-breakdown)
- [API Reference](#api-reference)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Observability](#observability)
- [Load Testing](#load-testing)

---

## Overview

The system implements the core functionality of a commercial cloud storage service:

- Authenticated users can **upload, download, delete, and list** files via a REST API
- Files are **shared via presigned URLs** with a configurable TTL — no credentials exposed to the recipient
- **Per-user storage quotas** are enforced at upload time
- All traffic flows through a **single NGINX entry point** with TLS termination, HTTP Basic Auth, and per-IP rate limiting
- The full infrastructure lifecycle is managed by **Terraform** — `terraform apply` brings the entire system up, `terraform destroy` tears it down completely

No graphical interface is required or provided. All interactions use `curl`, `httpie`, or Postman.

---

## Architecture

> Will add the architecture drawing in the near future.

---

## Component Breakdown

| Component | Role | Technology |
|-----------|------|------------|
| **NGINX** | Single external entry point: TLS termination, auth, rate limiting, reverse proxy | `nginx:latest` |
| **API Service** | Business logic: upload, download, share, quota enforcement | Python / FastAPI |
| **MinIO** | S3-compatible object storage; persists all user files across pod restarts | `minio/minio:latest` |
| **Prometheus** | Metrics collection scraping API pods, NGINX Exporter, MinIO, kube-state-metrics | `prom/prometheus` |
| **NGINX Exporter** | Exports NGINX runtime metrics to Prometheus at `:9113/metrics` | `nginx/nginx-prometheus-exporter` |
| **Grafana** | Dashboard visualisation and alerting (6-panel dashboard) | `grafana/grafana` |
| **Loki + Promtail** | Structured log aggregation, searchable from Grafana | `grafana/loki`, `grafana/promtail` |
| **HPA** | Scales API pods between 2 and 10 replicas at 60% CPU target | Kubernetes HorizontalPodAutoscaler |
| **Terraform** | Provisions the entire GCP infrastructure (VPC, GKE, IAM, Artifact Registry) | `hashicorp/terraform` |
| **k6** | Load and performance testing simulating 50 concurrent users | `grafana/k6` |

### Namespace Layout

```
storage/        — MinIO deployment and PVC
app/            — API deployments, HPA, ConfigMaps, Secrets
nginx/          — NGINX deployment and LoadBalancer service
observability/  — Prometheus, Grafana, Loki, Promtail, kube-state-metrics
```

---

## API Reference

Full interactive documentation is available at `https://<EXTERNAL_IP>/docs` (Swagger UI) and `https://<EXTERNAL_IP>/redoc` once the system is running.

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/auth/login` | Public | Authenticate; returns JWT |
| `POST` | `/files/upload` | Bearer JWT | Upload file (`multipart/form-data`). Returns `file_id` and metadata |
| `GET` | `/files` | Bearer JWT | List all files owned by the authenticated user (paginated) |
| `GET` | `/files/{file_id}` | Bearer JWT | Download a file by its unique identifier |
| `DELETE` | `/files/{file_id}` | Bearer JWT | Permanently delete a file from object storage |
| `POST` | `/files/{file_id}/share` | Bearer JWT | Generate a presigned URL with configurable TTL |
| `GET` | `/files/{file_id}/meta` | Bearer JWT | Return file metadata: name, size, MIME type, upload timestamp |
| `GET` | `/health` | Public | Liveness probe; returns HTTP 200 |
| `GET` | `/metrics` | Internal | Prometheus scrape endpoint (cluster-internal only) |

### Example Usage

```bash
# 1. Obtain a JWT
TOKEN=$(curl -s -X POST https://<EXTERNAL_IP>/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "password123"}' \
  | jq -r '.access_token')

# 2. Upload a file
curl -k -X POST https://<EXTERNAL_IP>/files/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@report.pdf"

# 3. List files
curl -k https://<EXTERNAL_IP>/files \
  -H "Authorization: Bearer $TOKEN"

# 4. Generate a presigned share link (TTL = 1 hour)
curl -k -X POST https://<EXTERNAL_IP>/files/<file_id>/share \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"ttl_seconds": 3600}'

# 5. Download a file
curl -k https://<EXTERNAL_IP>/files/<file_id> \
  -H "Authorization: Bearer $TOKEN" \
  -O -J
```

The `-k` flag skips TLS verification for the self-signed certificate.

---

## Getting Started

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Docker](https://docs.docker.com/get-docker/)
- A GCP project with billing enabled and the following APIs active:
  - Kubernetes Engine API
  - Artifact Registry API
  - Compute Engine API

### 1. Authenticate with GCP

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <YOUR_PROJECT_ID>
```

### 2. Provision Infrastructure with Terraform

```bash
cd terraform/

# Copy and fill in your project values
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set project_id, region, zone

terraform init
terraform plan
terraform apply
```

This provisions the VPC, subnet, GKE cluster, node pool, and Artifact Registry repository.

### 3. Connect kubectl to the Cluster

```bash
gcloud container clusters get-credentials dropbox-cluster \
  --zone <YOUR_ZONE>

kubectl get nodes   # both nodes should show Ready
```

### 4. Build and Push the API Image

```bash
cd api/
docker build -t <REGISTRY>/api:latest .
docker push <REGISTRY>/api:latest
```

Where `<REGISTRY>` is `us-central1-docker.pkg.dev/<PROJECT_ID>/dropbox-repo`.

### 5. Deploy MinIO

```bash
kubectl create namespace storage

kubectl create secret generic minio-secret \
  --from-literal=access-key=minioadmin \
  --from-literal=secret-key=minioadmin123 \
  --namespace storage

kubectl apply -f k8s/minio.yaml
kubectl get pods -n storage -w   # wait for Running
```

### 6. Deploy the API

```bash
kubectl apply -f k8s/api.yaml
kubectl get pods -n app -w       # wait for 2/2 Running
kubectl get hpa -n app           # verify HPA is configured
```

### 7. Generate TLS Certificate and htpasswd

```bash
# Self-signed TLS cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=dropbox-cluster/O=dropbox"

# Create credentials (user: alice, password: password123)
htpasswd -cb .htpasswd alice password123

# Load into Kubernetes
kubectl create secret tls nginx-tls-secret \
  --cert=tls.crt --key=tls.key -n nginx

kubectl create secret generic nginx-auth-secret \
  --from-file=.htpasswd -n nginx
```

### 8. Deploy NGINX

```bash
kubectl apply -f k8s/nginx.yaml

# Wait for external IP (~2 minutes)
kubectl get svc nginx-service -n nginx -w
```

Once `EXTERNAL-IP` is assigned, the system is live. Test it:

```bash
curl -k https://<EXTERNAL_IP>/health
# {"status": "ok"}
```

### 9. Deploy Observability Stack

```bash
kubectl apply -f k8s/observability.yaml
kubectl get pods -n observability -w

# Access Grafana locally
kubectl port-forward svc/grafana-service 3000:3000 -n observability
# Open http://localhost:3000 — login: admin / admin123

# Access Prometheus locally
kubectl port-forward svc/prometheus-service 9090:9090 -n observability
# Open http://localhost:9090
```

### Teardown

```bash
terraform destroy
```

This removes all GCP resources. Ensure you run this when done to avoid unexpected charges.

---

## Project Structure

```
project-dropbox/
├── terraform/                  # All infrastructure-as-code
│   ├── main.tf                 # Root module — calls all submodules
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars        # Your values (gitignored)
│   ├── network/                # VPC, subnet, secondary IP ranges
│   ├── cluster/                # GKE cluster and node pool
│   ├── iam/                    # Service accounts and RBAC
│   └── storage/                # Artifact Registry repository
│
├── api/                        # REST API source code
│   ├── main.py                 # All route handlers
│   ├── auth.py                 # JWT creation and validation
│   ├── storage.py              # MinIO/S3 interaction via boto3
│   ├── requirements.txt
│   └── Dockerfile
│
├── k8s/                        # Kubernetes manifests
│   ├── minio.yaml              # MinIO deployment, PVC, service
│   ├── api.yaml                # API deployment, service, HPA, bucket init job
│   ├── nginx.yaml              # NGINX deployment, ConfigMap, LoadBalancer service
│   └── observability.yaml      # Prometheus, Grafana, Loki, Promtail, alerting rules
│
├── nginx/
│   └── nginx.conf              # NGINX configuration (mounted as ConfigMap)
│
├── observability/
│   ├── prometheus.yml          # Scrape job configuration
│   ├── alerts.yml              # Alerting rules
│   └── grafana-dashboard.json  # Exported Grafana dashboard
│
├── tests/
│   └── load-test.js            # k6 load test script (50 users, 5 minutes)
│
└── docs/
    └── report.pdf              # Final project report
```

---

## Observability

The observability stack collects metrics, logs, and fires alerts across all system components.

**Prometheus** scrapes:
- API pods via `prometheus.io/scrape` annotations (port 8000, path `/metrics`)
- NGINX Exporter at `:9113/metrics` — exposes `nginx_http_requests_total`, `nginx_connections_active`, upstream latency histograms
- MinIO health endpoint at `:9000`
- `kube-state-metrics` for pod/node resource usage

**Grafana Dashboard** (6 panels):
- Request rate (RPS)
- Latency P50 / P95 / P99
- HTTP error rate (4xx / 5xx)
- Pod CPU and memory utilisation
- MinIO I/O throughput

**Alerting rules** (fire and resolve automatically):
- Error rate > 5% for 1 minute
- P95 latency > 2s for 1 minute
- Pod CPU utilisation > 80% for 2 minutes

**Log aggregation**: Loki + Promtail collect structured JSON logs from all components, searchable by pod and log level (`ERROR`, `WARN`) from within Grafana.

---

## Load Testing

A k6 script in `tests/load-test.js` simulates 50 concurrent users performing upload and download operations for 5 minutes.

```bash
k6 run tests/load-test.js
```

Metrics recorded: mean and P95 latency, requests per second, error rate, and replica count over time. The HPA is expected to scale the API deployment above 2 replicas during the test and return to 2 replicas afterwards.
