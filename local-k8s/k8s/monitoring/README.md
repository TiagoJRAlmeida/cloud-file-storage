# About this Chart - How it works

The `kube-prometheus-stack` chart is a huge monitoring project. 
As such, it is not really possible to analyze it all in depth.
One way to do it would be to create a the Chart from scratch, like how we did it with the MinIO Chart.
However that would be quite time consuming and not ideal when there is already such a popular and battle tested monitoring Chart like `kube-prometheus-stack`.
Instead, we create a new values file, and write only what we want to change. Then we install the Chart with the `-f` tag, and give it as argument the new values.yaml file.
What will happen is that Helm will install the Chart with the values from the template `values.yaml`, but then will read the new `values.yaml` and any values on it will be used to overwrite the Chart. 

## Usage example

```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f values-dev.yaml
```