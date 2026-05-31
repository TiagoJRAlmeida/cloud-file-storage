#!/bin/bash

set -e

echo -e "\n1. Removing API...\n"
kubectl delete -f api/ --namespace api --ignore-not-found
kubectl delete secret api-secret --namespace api --ignore-not-found
kubectl delete namespace api --ignore-not-found

echo -e "\n2. Removing NGINX...\n"
helm uninstall nginx --namespace nginx --ignore-not-found
kubectl delete namespace nginx --ignore-not-found

echo -e "\n3. Removing MinIO...\n"
helm uninstall minio --namespace storage --ignore-not-found
kubectl delete namespace storage --ignore-not-found

echo -e "\n4. Removing monitoring stack...\n"
helm uninstall monitoring --namespace monitoring --ignore-not-found
kubectl delete namespace monitoring --ignore-not-found

echo -e "\n5. Removing ClusterIssuers...\n"
kubectl delete -f cert-manager/clusterissuer-dev.yaml --ignore-not-found
kubectl delete -f cert-manager/clusterissuer-prod.yaml --ignore-not-found

echo -e "\n6. Removing cert-manager...\n"
helm uninstall cert-manager --namespace cert-manager --ignore-not-found
kubectl delete namespace cert-manager --ignore-not-found

echo -e "\nCluster cleaned! :D\n"
