#!/bin/bash

cd terraform

PG_PASSWORD_B64=$(kubectl get secret postgresql-secret -n default -o jsonpath="{.data.postgres-password}")

PG_PASSWORD=$(echo "$PG_PASSWORD_B64" | base64 --decode)

export TF_VAR_pg_password="$PG_PASSWORD"

terraform init

terraform apply -auto-approve