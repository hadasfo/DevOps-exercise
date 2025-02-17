#!/bin/bash

NAMESPACE="default"

kubectl apply -f yaml/postgresql-secret.yaml

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade --install postgresql bitnami/postgresql \
  --namespace $NAMESPACE \
  -f yaml/postgresql-values.yaml

echo "Waiting for PostgreSQL to be ready..."
kubectl rollout status statefulset/postgresql -n $NAMESPACE

kubectl get svc -n $NAMESPACE

echo "🔑 Retrieving PostgreSQL password..."
POSTGRES_PASSWORD=$(kubectl get secret postgresql-secret -n $NAMESPACE -o jsonpath="{.data.postgres-password}" | base64 --decode)

echo "📁 Creating 'devops' database if not exists..."
kubectl run pg-client --rm -it --image=bitnami/postgresql --env="PGPASSWORD=$POSTGRES_PASSWORD" -- \
    psql -h postgresql.default.svc.cluster.local -U postgres -d postgres -c "CREATE DATABASE devops;"

echo "📂 Creating 'logs' table if not exists..."
kubectl run pg-client --rm -it --image=bitnami/postgresql --env="PGPASSWORD=$POSTGRES_PASSWORD" -- \
    psql -h postgresql.default.svc.cluster.local -U postgres -d devops -c "
    CREATE TABLE IF NOT EXISTS logs (
        id SERIAL PRIMARY KEY,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );"


echo "✅ PostgreSQL Deployment Completed!"
kubectl run pg-client --rm -it --image=bitnami/postgresql --env="PGPASSWORD=$POSTGRES_PASSWORD" -- \
    psql -h postgresql.default.svc.cluster.local -U postgres -d devops -c "\dt"


