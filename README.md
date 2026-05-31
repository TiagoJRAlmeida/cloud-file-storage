# Message to Gabriel

There are 3 versions of this project. 


## local
The Local version, folder `/local`, is the system working without 
Terraform cloud infrastructure provision (That is why it's a local version) and also without
Kubernetes. It is just a testing site I built for the API, nginx, MinIO, Prometheus + Grafana, etc.
> You don't need, and probably really shouldn't, look at this folder. It will only confuse you more.

---
## local-k8s
The Local Kubernetes version, folder `/local-k8s`, is also without Terraform provisioned locally, however
this time with Kubernetes. The local K8s cluster is made using KinD (Kubernetes in Docker), and also I experimented
using Helm Charts, some of which I don't even know how it works fully, since it's so complex (the monitoring chart and
the cert-manager Chart).
> You probably also shouldn't look at this. Having kubernetes is helpful but as a lot of junk that will just confuse you.
> Also the K8s isn't really correct, since I use Helm Chart for everything since I was testing, but we only should be using for the MinIO.

---
## GCP 
Lastly, the Cloud version, folder `/GCP`. This one is the important one. However I haven't touched it since a long time ago so there are a lot of things (although now it's easy for me to fix) to do. Here are some out of the top of my head:

- The Terraform stuff:
    - I am not sure about the storage part. I think it should be used to save the terraform state, but I am not sure, and currently is configured to save the data form MinIO server (Which now I now it doesn't make sense, the Kubernetes cluster volumes deal with that).
    - The rest is fine I think.
    - Ended up removing the IAM folder too, have to analyze better it's use case. It's previous use case was to give permission to the MinIO K8s ServiceAccount to access the google storage bucket, however that is no longer needed. 

- The Kubernetes stuff:
    - The MinIO needs to be a Helm Chart. (Done, but need to see it better on the cloud context, primarily the PVC part.)
    - The others are correct I think, but missing a lot of things, like ServiceAccount, NetworkPolicy, Ingress, etc.
    - Since I already tested a lot with K8s the past few days I can probably fix this quickly.
    - Add the cert-manager Helm Chart.

- The Monitoring. I need to explore more the prometheus alert and stuff like logs with loki and promtail.

- The testing. This is really the only part I haven't touched at all, but from what I saw is pretty easy to make, just a quick and small js file.

- The Report. We need to make a report. I know the system like the back of my hand since I made it on different versions, so it should be easy to make. 

