#!/bin/bash
set -e

# Taint nodes labeled with app=mysql
for node in $(kubectl get nodes -l app=mysql -o jsonpath='{.items[*].metadata.name}'); do
  kubectl taint nodes "$node" app=mysql:NoSchedule --overwrite || true
done

# Install Ingress Controller (prerequisite)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for Ingress Controller to be ready
echo "Waiting for ingress controller..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

# Deploy todoapp helm chart (including mysql subchart)
helm upgrade --install todoapp .infrastructure/helm-chart/todoapp
