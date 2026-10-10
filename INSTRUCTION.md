# Validation Instructions

This document provides instructions on how to set up the environment, deploy the Helm charts, and validate the Kubernetes infrastructure for the ToDo application.

## Prerequisites

Ensure the following tools are installed on your machine:
- [Docker](https://docs.docker.com/get-docker/)
- [Kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm (v3+)](https://helm.sh/docs/intro/install/)
- [Python 3](https://www.python.org/)

---

## 1. Create Kind Cluster

Spin up the cluster using the provided configuration file:

```bash
kind create cluster --config cluster.yml
```

---

## 2. Inspect and Taint Nodes

Inspect the cluster nodes, labels, and taints:

```bash
kubectl get nodes --show-labels
kubectl describe nodes
```

Taint the nodes labeled with `app=mysql` with `app=mysql:NoSchedule`:

```bash
for node in $(kubectl get nodes -l app=mysql -o jsonpath='{.items[*].metadata.name}'); do
  kubectl taint nodes "$node" app=mysql:NoSchedule --overwrite
done
```

Verify that the taints are applied:

```bash
kubectl get nodes -l app=mysql -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints}{"\n"}{end}'
```

---

## 3. Deploy via bootstrap.sh

Run the bootstrap script to deploy prerequisites (Ingress NGINX Controller), taint nodes, and install the `todoapp` Helm chart with the `mysql` subchart:

```bash
./bootstrap.sh
```

Alternatively, deploy manually:

1. Install Ingress NGINX controller:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
   kubectl wait --namespace ingress-nginx \
     --for=condition=ready pod \
     --selector=app.kubernetes.io/component=controller \
     --timeout=180s
   ```

2. Install the Helm chart:
   ```bash
   helm upgrade --install todoapp .infrastructure/helm-chart/todoapp
   ```

---

## 4. Lint and Template Helm Charts

Verify the Helm chart syntax and templating:

```bash
helm lint .infrastructure/helm-chart/todoapp
helm template .infrastructure/helm-chart/todoapp -f .infrastructure/helm-chart/todoapp/values.yaml
```

---

## 5. Validate Resources and Generate output.log

Wait for the pods in both `mysql` and `todoapp` namespaces to be in `Running` and ready state:

```bash
kubectl wait --namespace mysql --for=condition=ready pod -l app=mysql --timeout=180s
kubectl wait --namespace todoapp --for=condition=ready pod -l app=todoapp --timeout=180s
```

Generate `output.log` containing all cluster resources:

```bash
kubectl get all,cm,secret,ing -A > output.log
```

---

## 6. Run the Validation Script

Execute the validation script to verify that required pods, HPA, and Ingress resources are present and running:

```bash
python .github/workflows/scripts/validate-output.py
```

Expected output:
```text
mysql pods running: True
todoapp pods running: True
todoapp horizontalpodautoscaler exists: True
todoapp ingress exists: True
All resources are found and are in a Running state.
```
