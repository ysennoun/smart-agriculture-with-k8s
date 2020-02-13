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
    clusterName=$1
    gcloud beta container clusters create "$clusterName" \
      --addons=HorizontalPodAutoscaling,HttpLoadBalancing,Istio \
      --machine-type="$MACHINE_TYPE" \
      --cluster-version=latest --zone="$COMPUTE_ZONE" \
      --enable-stackdriver-kubernetes \
      --enable-ip-alias \
      --enable-autoscaling --min-nodes="$MIN_NODES" --num-nodes "$NUM_NODES" --max-nodes="$MAX_NODES" \
      --enable-autorepair \
      --scopes cloud-platform \
       --quiet

    # Create an RBAC service account
    kubectl create clusterrolebinding cluster-admin-binding \
      --clusterrole=cluster-admin \
      --user=$(gcloud config get-value core/account)

    echo "End creation"
}

function get_k8_apiserver_url() {
  k8_apiserver_url=$(kubectl get svc -o json | jq '"\(.items[0].spec.ports[0].name)://\(.items[0].spec.clusterIP):\(.items[0].spec.ports[0].port)"')
  echo "$k8_apiserver_url" | tr -d '"'
}

function delete_k8s_cluster() {
    echo "Let's delete k8s cluster"
    clusterName=$1
    gcloud beta container clusters delete "$clusterName" --zone "$COMPUTE_ZONE" --quiet
    echo "End deletion"
}

function create_namespace(){
  env=$1
  kubectl create namespace "$env"
}

function deploy_knative(){
    env=$1
    echo "Let's deploy knative"
    kubectl apply --selector knative.dev/crd-install=true \
        --filename https://github.com/knative/serving/releases/download/v0.12.0/serving.yaml \
        --filename https://github.com/knative/eventing/releases/download/v0.12.0/eventing.yaml \
        --filename https://github.com/knative/serving/releases/download/v0.12.0/monitoring.yaml

    kubectl apply --filename https://github.com/knative/serving/releases/download/v0.12.0/serving.yaml \
        --filename https://github.com/knative/eventing/releases/download/v0.12.0/eventing.yaml \
        --filename https://github.com/knative/serving/releases/download/v0.12.0/monitoring.yaml

    echo "Configure Knative to use Broker and trigger"
    kubectl -n "$env" create serviceaccount eventing-broker-ingress
    kubectl -n "$env" create serviceaccount eventing-broker-filter

    kubectl -n "$env" create rolebinding eventing-broker-ingress \
      --clusterrole=eventing-broker-ingress \
      --serviceaccount=default:eventing-broker-ingress
    kubectl -n "$env" create rolebinding eventing-broker-filter \
      --clusterrole=eventing-broker-filter \
      --serviceaccount=default:eventing-broker-filter

    kubectl -n knative-eventing create rolebinding eventing-config-reader-default-eventing-broker-ingress \
      --clusterrole=eventing-config-reader \
      --serviceaccount=default:eventing-broker-ingress
    kubectl -n knative-eventing create rolebinding eventing-config-reader-default-eventing-broker-filter \
      --clusterrole=eventing-config-reader \
      --serviceaccount=default:eventing-broker-filter

    kubectl label namespace "$env" knative-eventing-injection=enabled #### IMPORTANT

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
    helm repo add elastic https://helm.elastic.co
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
    infrastructureRelease=$2
    helm install --namespace "$env" vernemq/vernemq --name-template "$infrastructureRelease-vernemq" \
      -f "$BASE_PATH/deploy/infrastructure/configuration/vernemq.yaml"
}

function delete_vernemq(){
    echo "Delete VerneMQ"
    env=$1
    infrastructureRelease=$2
    helm del "$infrastructureRelease-vernemq" --namespace "$env"
}

function get_vernemq_status(){
    echo "Get VerneMQ status"
    env=$1
    kubectl exec --namespace "$env" vernemq-cluster-0 /vernemq/bin/vmq-admin cluster show
}

function install_elasticsearch(){
    echo "Install Elasticsearch"
    env=$1
    infrastructureRelease=$2
    helm install --namespace "$env" --name-template "$infrastructureRelease-elasticsearch" elastic/elasticsearch \
      -f "$BASE_PATH/deploy/infrastructure/configuration/elasticsearch.yaml"
}

function delete_elasticsearch(){
    echo "Delete Elasticsearch"
    env=$1
    infrastructureRelease=$2
    helm del "$infrastructureRelease-elasticsearch" --namespace "$env"
}

function install_minio(){
    echo "Install Minio"
    env=$1
    infrastructureRelease=$2
    helm install --name-template "$infrastructureRelease-minio" \
      --namespace "$env" \
      -f "$BASE_PATH/deploy/infrastructure/configuration/minio.yaml" \
      stable/minio
}

function delete_minio(){
    echo "Delete Minio"
    env=$1
    infrastructureRelease=$2
    helm del "$infrastructureRelease-minio" --namespace "$env"
}