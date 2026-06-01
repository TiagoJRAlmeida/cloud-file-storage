# Nginx

Things the Nginx needs:

1. SSL Termination: Provided by cert-manager.
2. Reverse Proxy: Provided by the Ingress Controller.
3. Oauth2-proxy
4. Rate Limiting: Added to the nginx.conf


## 1. Adding Cert-Manager

For the cert-manager, configuring manually is a bit complex, so instead there is an helm chart that makes it easier to use.
All we need is to install it and a Cluster Issuer, that tells cert-manager how to issue the certificates and one gets created automatically by the Ingress annotation.
We can use 2 types of Cluster Issuers, one that generates a self-signed certificate (good for development) and one that creates an actual valid certificate.

**ClusterIssuer - Self-signed certificate version**
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned
spec:
  selfSigned: {}
```

**ClusterIssuer - Real valid certificate version**
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: email@example.com
    privateKeySecretRef:
      name: letsencrypt-private-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

To install the cert-manager Helm Chart is as simple as running the command:
```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```
> Important to make sure we are installing on the currect Kubernetes Cluster.

---

## 2. Adding the Reverse Proxy functionality

For this step we had 2 possible paths, either configure the `nginx.conf` or use an Ingress Controller.
Using Ingress seemed the better option for it's simplicity and more natural integration with Kubernetes, so we went with it.

Implementation can be found on the file `ingress.yaml`.

We need the Ingress Controller and for that we can install it using Helm with the following command:
```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace nginx \
  --create-namespace
```

---

## 3. Oauth2-Proxy

When we tested building the system locally using docker compose we saw that Oauth2-proxy was it's own component, that needed it's own service that ran the docker image.
Here it's not veery different. We will need to create a deployment just for the Oauth2-proxy.
