#!/bin/bash

NAMESPACE="jenkins"

kubectl apply -f yaml/jenkins-worker/jenkins-worker-sa.yaml
kubectl apply -f yaml/jenkins-worker/jenkins-worker-role.yaml
kubectl apply -f yaml/jenkins-worker/jenkins-worker-rolebinding.yaml
kubectl apply -f yaml/jenkins-worker/jenkins-worker-secret-role.yaml
kubectl apply -f yaml/jenkins-worker/jenkins-worker-secret-rolebinding.yaml

echo "📂 Creating ConfigMaps for Job DSL scripts..."
kubectl create configmap jenkins-init-dsl --from-file=jenkins/init.groovy --from-file=jenkins/job-dsl.groovy -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Patching Jenkins StatefulSet to include Job DSL scripts..."
kubectl patch statefulset jenkins -n $NAMESPACE --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "jenkins-init-dsl",
      "configMap": {
        "name": "jenkins-init-dsl"
      }
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "jenkins-init-dsl",
      "mountPath": "/var/jenkins_home/init.groovy",
      "subPath": "init.groovy"
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "jenkins-init-dsl",
      "mountPath": "/var/jenkins_home/job-dsl.groovy",
      "subPath": "job-dsl.groovy"
    }
  }
]'

echo "🔄 Restarting Jenkins to apply changes..."
kubectl rollout restart statefulset jenkins -n $NAMESPACE
