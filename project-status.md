# Cloud File Storage — Project Status

## What's Done ✅

### Task 1 — Base Infrastructure (Terraform)
- GKE cluster provisioned on GCP via Terraform
- Network module (VPC, subnets)
- Cluster module (GKE)
- Namespaces created: `api`, `storage`, `nginx`, `observability`
- Terraform IAM and storage modules removed (not needed without GCS backend for MinIO)

### Task 2 — NGINX, SSL, Authentication
- cert-manager installed via Helm, Let's Encrypt ClusterIssuer configured
- Valid TLS certificate issued for `storage.t1gs.com` ✅
- HTTP → HTTPS redirect working (via Cloudflare + ingress) ✅
- NGINX Ingress Controller installed via Helm
- OAuth2-Proxy deployed with Google OIDC — browser login flow working ✅
- Rate limiting configured via ingress annotation (`limit-rps: 10`)
- Public routes (`/auth/login`, `/health`) exposed without OAuth2 via separate ingress
- `snippet-annotations` enabled on ingress controller

### Task 3 — File API and MinIO
- FastAPI API implemented with all required endpoints:
  - `POST /auth/login` ✅
  - `POST /files/upload` ✅
  - `GET /files` ✅
  - `GET /files/{file_id}` ✅
  - `DELETE /files/{file_id}` ✅
  - `POST /files/{file_id}/share` ✅
  - `GET /files/{file_id}/meta` ✅
  - `GET /health` ✅
  - `GET /metrics` ✅
- JWT authentication with argon2 password hashing ✅
- Per-user quota enforcement ✅
- boto3 S3 client connecting to MinIO ✅
- Prometheus metrics instrumented in API ✅
- API deployed to GKE with 2 replicas ✅
- HPA configured (min 2, max 10, CPU target 60%) ✅
- API image pushed to Docker Hub ✅
- MinIO deployed via custom Helm chart (StatefulSet + PVC) ✅
- MinIO user `apiuser` created manually ✅
- File upload/download working via Swagger UI ✅

---

## What's Broken or Incomplete ⚠️

### Actively Broken
- **MinIO provisioning job** is stuck/hanging on every fresh deploy
  - Root cause: likely the init container `wget` or network policy still blocking
  - Workaround: manually create `apiuser` via `kubectl exec` into MinIO pod
  - Needs fixing so `init.sh` works end-to-end without manual intervention

- **curl workflow broken for protected routes** — `/files` and other JWT-protected
  endpoints return 302 because OAuth2-Proxy intercepts Bearer token requests
  - Fix: add `--skip-auth-regex` and `--pass-authorization-header=true` to
    OAuth2-Proxy deployment args (started but not completed)

### Missing from Task 2
- **NGINX Prometheus Exporter** not deployed — required by assignment (`:9113/metrics`)
  - Needs a sidecar or separate deployment exposing NGINX metrics to Prometheus

### Missing — Task 4 (Observability) — Not Started
- [ ] Prometheus deployment (`observability/` folder, plain YAML)
  - `prometheus.yml` with scrape jobs for: API pods, NGINX exporter, MinIO, kube-state-metrics
  - Alerting rules file with 3 required alerts:
    - Error rate > 5%
    - P95 latency > 2s
    - Pod CPU > 80%
- [ ] Grafana deployment (plain YAML)
  - Dashboard JSON with minimum 6 panels:
    - Request rate (RPS)
    - Latency P50/P95/P99
    - HTTP error rate (4xx/5xx)
    - Pod CPU and memory utilisation
    - MinIO I/O throughput
- [ ] Loki + Promtail for log aggregation
  - Structured JSON logs searchable by pod and log level from Grafana
- [ ] Alert firing verification (simulate condition, confirm alert fires and resolves)

### Missing — Task 5 (Performance Testing) — Not Started
- [ ] k6 or Artillery load test script
  - 50 concurrent users, upload + download, 5 minutes
- [ ] Metrics collection during test (latency mean/P95, RPS, error rate, replica count)
- [ ] HPA autoscaling verification during load test
- [ ] Grafana screenshots + k6 output for report

### Missing — Deliverables
- [ ] PDF report (max 20 pages)
  - Architecture design decisions
  - Challenges encountered (plenty of material here)
  - Updated architecture diagram
  - Performance test results and analysis
- [ ] `README.md` with complete setup instructions
- [ ] Swagger/OpenAPI spec committed to repo
- [ ] Grafana dashboard JSON exported and committed
- [ ] k6/Artillery scripts committed under `tests/`
- [ ] Git repository shared with course instructor on gitlab.up.pt

---

## Suggested Order to Finish

1. **Fix the curl / OAuth2-Proxy issue** — add `--skip-auth-regex` flags to OAuth2-Proxy
   deployment so API testing with curl works properly
2. **Fix the MinIO provisioning job** — get `init.sh` to work end-to-end without manual steps
3. **Add NGINX Prometheus Exporter** — required for Task 2 validation and Task 4 scraping
4. **Deploy Prometheus** — plain YAML, scrape jobs for all components
5. **Deploy Grafana** — plain YAML, build the 6-panel dashboard
6. **Deploy Loki + Promtail** — log aggregation
7. **Configure and test alerting rules**
8. **Write and run k6 load test**, capture metrics, verify HPA scaling
9. **Write the PDF report**
10. **Clean up repo** — README, OpenAPI spec, Conventional Commits, no plaintext secrets

---

## Known Decisions and Rationale

| Decision | Rationale |
|---|---|
| MinIO via custom Helm chart | Stateful deployment complexity worth abstracting |
| cert-manager via Helm | CRD/webhook setup too complex to hand-write |
| NGINX Ingress Controller via Helm | Replaces hand-rolled nginx deployment |
| Everything else plain YAML | Full transparency for demo and grading |
| Docker Hub for API image | Simpler than Artifact Registry for student project |
| Google OAuth as OIDC provider | Already have GCP project, zero extra infrastructure |
| Separate ingress for public routes | Avoids `configuration-snippet` annotation (blocked by default) |
| boto3 over MinIO SDK | S3-compatible, more portable if switching to AWS S3 later |
