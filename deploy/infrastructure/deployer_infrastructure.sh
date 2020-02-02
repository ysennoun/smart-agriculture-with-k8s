#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

ENVIRONMENT="$ENVIRONMENT"
COMPUTE_ZONE="$COMPUTE_ZONE"
MIN_NODES=1
MAX_NODES=10
NUM_NODES=3
MACHINE_TYPE=n1-standard-4
CLUSTER_NAME="smart-agriculture-cluster"
INFRASTRUCTURE_RELEASE="smart-agriculture-infrastructure"

## FUNCTIONS
function activate_billing(){
    PROJECT=$1
    echo "Activate billing"
    gcloud config set core/project "$PROJECT"
}

function enable_apis(){
    echo "Activate APIs"
    gcloud services enable \
         cloudapis.googleapis.com \
         cloudbuild.googleapis.com \
         container.googleapis.com \
         containerregistry.googleapis.com \
         --quiet
}

function create_k8s_cluster() {
    echo "Let's create k8s cluster"
    gcloud beta container clusters create "$CLUSTER_NAME" \
       --addons=HorizontalPodAutoscaling,HttpLoadBalancing,Istio,CloudRun \
       --cluster-version=latest \
       --enable-stackdriver-kubernetes\
       --enable-ip-alias \
       --enable-autorepair \
       --scopes cloud-platform \
       --zone "$COMPUTE_ZONE"  \
       --num-nodes "$NUM_NODES" \
       --machine-type "$MACHINE_TYPE" \
       --enable-autoscaling \
       --min-nodes="$MIN_NODES" \
       --max-nodes="$MAX_NODES" \
       --quiet
    # Create an RBAC service account
    kubectl create serviceaccount tiller -n kube-system
    # Bind the cluster-admin role to the service account
    kubectl create clusterrolebinding tiller \
       --clusterrole=cluster-admin \
       --serviceaccount kube-system:tiller
    echo "End creation"
}

function get_k8_apiserver_url() {
  k8_apiserver_url=$(kubectl cluster-info | head -n 1 | rev | cut -d' ' -f 1 | rev)
  echo "$k8_apiserver_url"
}

function delete_k8s_cluster() {
    echo "Let's delete k8s cluster"
    gcloud beta container clusters delete "$CLUSTER_NAME" --zone "$COMPUTE_ZONE" --quiet
    echo "End deletion"
}

function create_namespace(){
  env=$1
  kubectl create namespace "$env"
}

function deploy_knative(){
    echo "Let's deploy knative"
    kubectl apply --selector knative.dev/crd-install=true \
        --filename https://github.com/knative/serving/releases/download/v0.12.0/serving.yaml \
        --filename https://github.com/knative/eventing/releases/download/v0.12.0/eventing.yaml \
        --filename https://github.com/knative/serving/releases/download/v0.12.0/monitoring.yaml
    kubectl apply --filename https://github.com/knative/serving/releases/download/v0.12.0/serving.yaml \
        --filename https://github.com/knative/eventing/releases/download/v0.12.0/eventing.yaml \
        --filename https://github.com/knative/serving/releases/download/v0.12.0/monitoring.yaml
    # Grant cluster-admin permissions to the current user
    kubectl create clusterrolebinding cluster-admin-binding \
         --clusterrole=cluster-admin \
         --user=$(gcloud config get-value core/account)
    echo "End deployment"
}

function visualize_knative_deployment(){
    echo "Let's visualize deployment knative"
    kubectl get pods --namespace knative-serving
    kubectl get pods --namespace knative-eventing
    kubectl get pods --namespace knative-monitoring
}

function get_istio_ingress_gateway_ip(){
    ISTIO_INGRESS_GATEWAY_IP_ADDRESS=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "$ISTIO_INGRESS_GATEWAY_IP_ADDRESS"
}

function set_helm_repos(){
    echo "Add Helm VerneMQ and stable repos"
    helm repo add vernemq https://vernemq.github.io/docker-vernemq
    helm repo add stable https://kubernetes-charts.storage.googleapis.com
    helm repo update
}

function set_docker(){
  hostname=$1
  gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin "https://$hostname"
}

function install_vernemq(){
    echo "Install VerneMQ"
    env=$1
    helm install vernemq/vernemq --name-template "$INFRASTRUCTURE_RELEASE-vernemq" --namespace "$env" --set DOCKER_VERNEMQ_ACCEPT_EULA=yes
}

function delete_vernemq(){
    echo "Delete VerneMQ"
    env=$1
    helm del --purge "$INFRASTRUCTURE_RELEASE-vernemq" --namespace "$env"
}

function get_vernemq_status(){
    echo "Get VerneMQ status"
    env=$1
    kubectl exec --namespace "$env" vernemq-cluster-0 /vernemq/bin/vmq-admin cluster show
}

function install_elasticsearch(){
    echo "Install Elasticsearch"
    env=$1
    helm install --namespace "$env" --name-template "$INFRASTRUCTURE_RELEASE-elasticsearch" stable/elasticsearch
}

function delete_elasticsearch(){
    echo "Delete Elasticsearch"
    env=$1
    helm del --purge "$INFRASTRUCTURE_RELEASE-elasticsearch" --namespace "$env"
}

function install_minio(){
    echo "Install Minio"
    env=$1
    helm install --name-template "$INFRASTRUCTURE_RELEASE-minio" \
      --namespace "$env" \
      --set buckets[0].name=bucket,buckets[0].policy=none,buckets[0].purge=true \
      stable/minio
}

function delete_minio(){
    echo "Delete Minio"
    env=$1
    helm del --purge "$INFRASTRUCTURE_RELEASE-minio" --namespace "$env"
}