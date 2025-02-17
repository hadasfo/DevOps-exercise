#!/bin/bash

NAMESPACE="jenkins"
WORKER_NAMESPACE="jenkins-workers"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $WORKER_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

helm repo add jenkins https://charts.jenkins.io
helm repo update

kubectl apply -f yaml/jenkins-secret-access.yaml

helm upgrade --install jenkins jenkins/jenkins \
  --namespace $NAMESPACE \
  -f yaml/jenkins-values.yaml

echo "Waiting for Jenkins StatefulSet to be created..."
while [[ -z $(kubectl get statefulset jenkins -n $NAMESPACE --ignore-not-found) ]]; do
  sleep 5
  echo "Still waiting for StatefulSet..."
done

echo "Waiting for Jenkins to be ready..."
kubectl rollout status statefulset jenkins -n $NAMESPACE

echo "Jenkins Admin Password:"
kubectl get secret --namespace $NAMESPACE jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
echo ""

kubectl exec -it $(kubectl get pod -n jenkins -l app.kubernetes.io/name=jenkins -o jsonpath="{.items[0].metadata.name}") -n jenkins -- printenv | grep POSTGRES

