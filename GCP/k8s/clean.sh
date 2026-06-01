#!/bin/bash

set -e

# 4. NGINX
echo -e "\n4. Removing Nginx...\n"

echo -e "\n4.4. Removing the Ingress...\n"
kubectl delete -f nginx/ingress.yaml --ignore-not-found

echo -e "\n4.3. Uninstalling the Ingress Controller...\n"
helm uninstall ingress-nginx --namespace nginx

echo -e "\n4.2. Removing Oauth2-Proxy...\n"
kubectl delete -f nginx/oauth2-proxy --ignore-not-found

echo -e "\n4.1. Removing the Cluster Issuer...\n"
kubectl delete -f nginx/clusterissuer.yaml --ignore-not-found

# 3. cert-manager
echo -e "\n3. Uninstalling cert-manager...\n"
helm uninstall cert-manager --namespace cert-manager
kubectl delete namespace cert-manager --ignore-not-found

# 2. API
echo -e "\n2. Removing the API...\n"
kubectl delete -f api/ --namespace api --ignore-not-found
kubectl delete secret api-secret --namespace api --ignore-not-found

# 1. MinIO
echo -e "\n1. Uninstalling MinIO Chart...\n"
helm uninstall minio --namespace storage

# 0. Namespaces
echo -e "\n0. Removing Namespaces...\n"
kubectl delete -f namespaces.yaml --ignore-not-found

echo -e "\nDone! :D\n"
