# API

## API Modules

> **To-do:** I need to explain the functions of of the 3 files, `main.py`, `auth.py` and `storage.py`. Too much work right now CBA. Will do it later.

## Pushing the Docker Image to Google Registry

In order to deploy the API using Kubernetes, we first need to build a container image and push it to Google Cloud registry. Currently the registry being used is `Artifact Registry`.

**1) Enable Artifact Registry API**
```bash
gcloud services enable artifactregistry.googleapis.com
```

**2) Create a repository**
```bash
gcloud artifacts repositories create cloud-storage-system-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Cloud Storage System Project Repository"
```

**3) Configure Docker to authenticate with GCP**
```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

**4) Build and tag your image**
```bash
docker build -t us-central1-docker.pkg.dev/project-194a4c0b-f19a-4314-a3c/cloud-storage-system-repo/api:latest .
```

**5) Push it**
```bash
docker push us-central1-docker.pkg.dev/project-194a4c0b-f19a-4314-a3c/cloud-storage-system-repo/api:latest
```

**6) Verify it's there**
```bash
gcloud artifacts docker images list us-central1-docker.pkg.dev/project-194a4c0b-f19a-4314-a3c/cloud-storage-system-repo
```
