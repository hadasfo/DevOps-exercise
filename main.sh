#!/bin/bash
export CLUSTER_NAME="hadas-cluster"

ACTION=$1

export KUBECONFIG=$(k3d kubeconfig write $CLUSTER_NAME)

if [ "$ACTION" == "install" ]; then
  script/pre-install.sh
  script/create-cluster.sh
  script/deploy-postgres.sh
  script/deploy-jenkins.sh
  script/deploy-jenkins-jobs.sh
  script/deploy-traefik.sh
  script/deploy-grafana.sh
elif [ "$ACTION" == "uninstall" ]; then
  cd terraform
  terraform destroy
  k3d cluster delete $CLUSTER_NAME
else
  echo "Usage: $0 {install|uninstall}"
fi