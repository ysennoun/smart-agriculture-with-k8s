#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

ENVIRONMENT="$ENVIRONMENT"
COMPUTE_ZONE="$COMPUTE_ZONE"
MIN_NODES=1
MAX_NODES=5
NUM_NODES=3
MACHINE_TYPE=n1-standard-2
CLUSTER_NAME="$ENVIRONMENT-smart-agriculture-cluster"
INFRASTRUCTURE_RELEASE="$ENVIRONMENT-smart-agriculture-infrastructure"

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
         containerregistry.googleapis.com
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
       --max-nodes="$MAX_NODES"
    # Create an RBAC service account
    kubectl create serviceaccount tiller -n kube-system
    # Bind the cluster-admin role to the service account
    kubectl create clusterrolebinding tiller \
       --clusterrole=cluster-admin \
       --serviceaccount kube-system:tiller
    # Install Tiller with the service account enabled
    helm init --service-account tiller
    echo "End creation"
}

function delete_k8s_cluster() {
    echo "Let's delete k8s cluster"
    gcloud beta container clusters delete "$CLUSTER_NAME" --zone "$COMPUTE_ZONE"
    echo "End deletion"
}

function deploy_knative(){
    echo "Let's deploy knative"
    kubectl apply --selector knative.dev/crd-install=true \
       --filename https://github.com/knative/serving/releases/download/v0.8.0/serving.yaml \
       --filename https://github.com/knative/eventing/releases/download/v0.8.0/eventing.yaml \
       --filename https://github.com/knative/serving/releases/download/v0.8.0/monitoring.yaml
    kubectl apply --filename https://github.com/knative/serving/releases/download/v0.8.0/serving.yaml \
        --filename https://github.com/knative/eventing/releases/download/v0.8.0/eventing.yaml \
        --filename https://github.com/knative/serving/releases/download/v0.8.0/monitoring.yaml
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

function export_istio_ingress_gateway_ip(){
    export ISTIO_INGRESS_GATEWAY_IP_ADDRESS=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
}

function add_helm_vernemq_repo(){
    echo "Add Helm VerneMQ repo"
    URL="https://vernemq.github.io/docker-vernemq"
    helm repo add vernemq ${URL}
    helm repo update
}

function install_vernemq(){
    echo "Install VerneMQ"
    helm install vernemq/vernemq --name "$INFRASTRUCTURE_RELEASE-vernemq"
}

function delete_vernemq(){
    echo "Delete VerneMQ"
    helm del --purge "$INFRASTRUCTURE_RELEASE-vernemq"
}

function get_vernemq_status(){
    echo "Get VerneMQ status"
    kubectl exec --namespace default vernemq-cluster-0 /vernemq/bin/vmq-admin cluster show
}

function install_elasticsearch(){
    echo "Install Elasticsearch"
    helm install --name "$INFRASTRUCTURE_RELEASE-elasticsearch" stable/elasticsearch
}

function delete_elasticsearch(){
    echo "Delete Elasticsearch"
    helm del --purge "$INFRASTRUCTURE_RELEASE-elasticsearch"
}

function install_minio(){
    echo "Install Minio"
    helm install --name "$INFRASTRUCTURE_RELEASE-minio" stable/minio
}

function delete_minio(){
    echo "Delete Minio"
    helm del --purge "$INFRASTRUCTURE_RELEASE-minio"
}