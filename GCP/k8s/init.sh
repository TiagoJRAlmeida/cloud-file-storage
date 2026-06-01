#!/bin/bash

set -e

source .env

helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 0. Creating namespaces
echo -e "\n0. Creating Namespaces...\n"
kubectl apply -f namespaces.yaml

# 1. MinIO
echo -e "\n1. Installing MinIO Chart...\n"
helm install minio ./storage/minio \
    --namespace storage \
    --set auth.rootUser=$MINIO_ROOT_USER \
    --set auth.rootPassword=$MINIO_ROOT_PASSWORD \
    --set provisioning.users[0].password=$MINIO_API_PASSWORD

# 2. API
echo -e "\n2. Applying the API yaml files...\n"
kubectl create secret generic api-secret \
    --namespace api \
    --from-literal=minio-access-key=$MINIO_API_USER \
    --from-literal=minio-secret-key=$MINIO_API_PASSWORD \
    --from-literal=jwt-secret=$JWT_SECRET
kubectl apply -f api/ --namespace api

# 3. cert-manager
echo -e "\n3. Installing cert-manager Chart...\n"
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set crds.enabled=true

kubectl wait --namespace cert-manager \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/instance=cert-manager \
    --timeout=120s

# 4. NGINX
echo -e "\n4. Applying the Nginx yaml files...\n"

echo -e "\n4.1. Applying the Cluster Issuer...\n"
kubectl apply -f nginx/clusterissuer.yaml

echo -e "\n4.2. Creating Oauth2-Proxy...\n"
kubectl create secret generic oauth2-proxy-secret \
  --namespace nginx \
  --from-literal=client-id=$OAUTH2_CLIENT_ID \
  --from-literal=client-secret=$OAUTH2_CLIENT_SECRET \
  --from-literal=cookie-secret=$OAUTH2_COOKIE_SECRET
kubectl apply -f nginx/oauth2-proxy

echo -e "\n4.3. Installing the Ingress Controller...\n"
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace nginx \
  --create-namespace

kubectl wait --namespace nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=120s

echo -e "\n4.4. Applying the Ingress...\n"
kubectl apply -f nginx/ingress.yaml

echo -e "\nDone! :D\n"
