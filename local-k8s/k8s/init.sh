#!/bin/bash

set -e

helm repo add jetstack https://charts.jetstack.io
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update  # updates all three at once

# 1. cert-manager
echo -e "\n1. Installing cert-manager Chart...\n"
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set crds.enabled=true

# Wait for cert-manager webhooks to be ready
kubectl wait --namespace cert-manager \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/instance=cert-manager \
    --timeout=120s

# 2. ClusterIssuers
echo -e "\n2. Applying ClusterIssuers...\n"
kubectl apply -f cert-manager/clusterissuer-dev.yaml
kubectl apply -f cert-manager/clusterissuer-prod.yaml

# 3. Monitoring (must be before anything that uses PrometheusRule/ServiceMonitor)
echo -e "\n3. Installing the monitoring stack Chart (This one can take a while)...\n"
helm install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --set grafana.adminPassword=$GRAFANA_PASSWORD \
    -f monitoring/values.yaml

# Wait for Prometheus Operator CRDs to be ready
kubectl wait --namespace monitoring \
    --for=condition=ready pod \
    --all \
    --timeout=180s

# 4. MinIO
echo -e "\n4. Installing MinIO Chart...\n"
helm install minio ./storage/minio \
    --namespace storage \
    --create-namespace \
    --set auth.rootUser=$MINIO_ROOT_USER \
    --set auth.rootPassword=$MINIO_ROOT_PASSWORD


# 5. NGINX
echo -e "\n5. Installing Nginx Chart...\n"
helm install nginx ./nginx \
    --namespace nginx \
    --create-namespace \
    -f ./nginx/nginx/values-dev.yaml

# 6. API
echo -e "\n6. Applying the API yaml files...\n"
kubectl create namespace api --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic api-secret \
    --namespace api \
    --from-literal=minio-access-key=$MINIO_API_USER \
    --from-literal=minio-secret-key=$MINIO_API_PASSWORD \
    --from-literal=jwt-secret=$JWT_SECRET
kubectl apply -f api/ --namespace api

echo -e "\nDone! :D\n"
