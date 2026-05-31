# Setup

## Authenticate with gcloud

```bash
gcloud auth login
gcloud config set project <project_id>
```

## Connect to the cluster deployed on the cloud

```bash
gcloud container clusters get-credentials primary-cluster --zone us-central1-a
kubectl get nodes  # should show 1 node as Ready
```
> If an error related to `gke-gcloud-auth-plugin` appears, it means we need to install the plugin. That can be done with the command `gcloud components install gke-gcloud-auth-plugin` 

## Apply the manifest

```bash
kubectl apply -f storage/
kubectl apply -f api/
kubectl apply -f nginx/
```

## Verify if it is running

```bash
kubectl get pods -n storage
# wait until STATUS shows Running

kubectl get pvc -n storage
# should show Bound
```
