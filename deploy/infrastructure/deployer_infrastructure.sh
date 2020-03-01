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
NUM_NODES=1 #3
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
  echo "Create Namespace"
  kubectl create namespace "$env"
}

function delete_namespace(){
  env=$1
  echo "Delete Namespace"
  kubectl delete namespace "$env"
}

function install_infrastructure(){
  release=$1
  env=$2
  infrastructureRelease=$3
  echo "Get certificates"
  mqttCA=$(get_ssl_certificates_in_base64 "vernemq" "ca.crt")
  mqttTLS=$(get_ssl_certificates_in_base64 "vernemq" "tls.crt")
  mqttKey=$(get_ssl_certificates_in_base64 "vernemq" "tls.key")
  esCA=$(get_ssl_certificates_in_base64 "elasticsearch" "ca.crt")
  esTLS=$(get_ssl_certificates_in_base64 "elasticsearch" "tls.crt")
  esKey=$(get_ssl_certificates_in_base64 "elasticsearch" "tls.key")

  echo "Install Elasticsearch"
  kubectl apply -f https://download.elastic.co/downloads/eck/1.0.1/all-in-one.yaml
  helm upgrade --install --debug \
    "$release" \
    "$BASE_PATH/deploy/infrastructure" \
    --set infrastructureRelease="$infrastructureRelease" \
    --set namespace="$env" \
    --set mqttCA="$mqttCA" \
    --set mqttTLS="$mqttTLS" \
    --set mqttKey="$mqttKey" \
    --set esCA="$esCA" \
    --set esTLS="$esTLS" \
    --set esKey="$esKey"

  echo "Install VerneMQ"
  helm upgrade --install --namespace "$env" "$infrastructureRelease-vernemq" vernemq/vernemq \
    -f "$BASE_PATH/deploy/infrastructure/configuration/vernemq.yaml"

  #echo "Install Minio"
  #helm upgrade --install --namespace "$env" "$infrastructureRelease-minio" \
  #  -f "$BASE_PATH/deploy/infrastructure/configuration/minio.yaml" \
  #  stable/minio
}

function delete_infrastructure(){
  release=$1
  env=$2
  infrastructureRelease=$3

  echo "Delete Minio"
  helm del "$infrastructureRelease-minio" --namespace "$env"

  echo "Delete VerneMQ"
  helm del "$infrastructureRelease-vernemq" --namespace "$env"

  echo "Delete Elasticsearch and Namespace"
  helm delete "$release"
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

    #kubectl label namespace "$env" knative-eventing-injection=enabled #### IMPORTANT

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


function get_ssl_certificates_in_base64(){
  server=$1
  file=$2
  echo $(cat "$BASE_PATH/deploy/certificates/$server/$file" | base64)
}