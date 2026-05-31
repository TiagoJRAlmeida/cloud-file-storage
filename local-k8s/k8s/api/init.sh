kubectl create secret generic api-secret \
  --namespace api \
  --from-literal=minio-access-key=$MINIO_API_USER \
  --from-literal=minio-secret-key=$MINIO_API_PASSWORD \
  --from-literal=jwt-secret=$JWT_SECRET
