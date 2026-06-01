# For the Demo

Test using port forwarding:

# Prometheus
kubectl port-forward -n observability svc/prometheus 9090:9090

# Grafana
kubectl port-forward -n observability svc/grafana 3000:3000
