#!/bin/bash

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists k3d; then
    echo "k3d is not installed. Please install it first."
    exit 1
fi

if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo "Cluster $CLUSTER_NAME already exists. Skipping creation."
else
    echo "Creating k3d cluster: $CLUSTER_NAME..."
    k3d cluster create --config yaml/cluster.yaml
fi

kubectl cluster-info
kubectl get nodes
echo "K3d cluster setup completed!"
