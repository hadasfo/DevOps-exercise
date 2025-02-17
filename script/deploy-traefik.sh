#!/bin/bash

# Deploy Traefik
echo "📦 Installing Traefik with Helm..."
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace kube-system \
  -f yaml/traefik-values.yaml \
  --set service.port=9000

# Wait for Traefik to be Ready
echo "⏳ Waiting for Traefik to be ready..."
kubectl rollout status deployment traefik -n kube-system

# Deploy Grafana
kubectl create namespace monitoring
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --set service.type=ClusterIP \
  --set service.port=3000

kubectl patch svc traefik -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/ports/-",
    "value": {
      "name": "traefik-dashboard",
      "port": 9000,
      "protocol": "TCP",
      "targetPort": 9000
    }
  }
]'


# Apply Ingress Routes for Jenkins, Grafana, and Traefik
echo "🌍 Creating Ingress routes for Jenkins, Grafana, and Traefik dashboard..."
kubectl create namespace monitoring
kubectl apply -f yaml/ingress-routes.yaml

# Show Access Information
echo "✅ Deployment complete!"
echo "🔗 Access Jenkins at: http://jenkins.local"
echo "🔗 Access Grafana at: http://grafana.local"
echo "🔗 Access Traefik Dashboard at: http://traefik.local"
