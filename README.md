# Overview

There are 3 versions of this project.

## local

The Local version, folder `/local`, is the system working without
Terraform cloud infrastructure provision (That is why it's a local version) and also without
Kubernetes. It is just a testing site built for the API, nginx, MinIO, Prometheus + Grafana, etc.

---

## local-k8s

The Local Kubernetes version, folder `/local-k8s`, is also without Terraform provisioned locally, however
this time with Kubernetes. The local K8s cluster is made using KinD (Kubernetes in Docker), and also I experimented
using Helm Charts, some of which I don't even know how it works fully, since it's so complex (the monitoring chart and
the cert-manager Chart).

---

## GCP

Lastly, the Cloud version, folder `/GCP`.
