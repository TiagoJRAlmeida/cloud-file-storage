# Setup

## Connect to the cluster deployed on the cloud

```bash
gcloud container clusters get-credentials primary-cluster --zone us-central1-a
kubectl get nodes  # should show 2 nodes as Ready
```
> If an error related to `gke-gcloud-auth-plugin` appears, it means we need to install the plugin. That can be done with the command `gcloud components install gke-gcloud-auth-plugin` 

## Create the namespace and secret

```bash
kubectl create namespace storage

kubectl create secret generic minio-secret \
  --from-literal=access-key=minioadmin \
  --from-literal=secret-key=minioadmin123 \
  --namespace storage
```

## Apply the manifest

```bash
kubectl apply -f minio.yaml
```

## Verify if it is running

```bash
kubectl get pods -n storage
# wait until STATUS shows Running

kubectl get pvc -n storage
# should show Bound
```
