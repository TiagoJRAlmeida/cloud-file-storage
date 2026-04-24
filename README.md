# cloud-file-storage-system

A Dropbox-like platform built on Kubernetes, NGINX, and MinIO

# Project Structure

```bash
project/
├── terraform/  # All IaC code
│   ├── network/
│   ├── cluster/
│   └── iam/
├── k8s/    # Kubernetes manifests (Deployments, Services, HPA, Secrets ...)
├── nginx/  # nginx.conf and local docker-compose for development
├── api/    # API source code + Dockerfile
├── observability/  # prometheus.yml, Grafana dashboards JSON, alerting rules
├── tests/     # k6 / Artillery scripts
├── docs/      # Final report (PDF)
└── README.md  # Setup and usage instructions
```
