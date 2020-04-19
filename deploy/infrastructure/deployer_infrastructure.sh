#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

. "$BASE_PATH/deploy/cluster/deployer_cluster.sh"

## FUNCTIONS
function create_namespace(){
  env=$1
  namespace_exit=$(kubectl get namespace -o name | grep -i "$env" | tr -d '\n')
  echo "$namespace_exit"
  if [ -z "$namespace_exit" ]
  then
        echo "Create namespace"
        kubectl create namespace "$env"
  else
        echo "Namespace already exists"
  fi
}

function delete_namespace(){
  env=$1
  echo "Delete Namespace"
  kubectl delete namespace "$env"
}

function install_infrastructure(){
  env=$1
  region=$2
  s3aAccessKey=$3
  s3aSecretKey=$4
  mqttIndexerPass=$5
  mqttDevicePass=$6
  backEndUserPass=$7

  echo "Get certificates from local or secrets if exists"
  mqttCA=$(get_ssl_certificates_in_base64 "vernemq" "ca.crt")
  mqttTLS=$(get_ssl_certificates_in_base64 "vernemq" "tls.crt")
  mqttKey=$(get_ssl_certificates_in_base64 "vernemq" "tls.key")
  backEndTLS=$(get_ssl_certificates_in_base64 "back-end" "tls.crt")
  backEndKey=$(get_ssl_certificates_in_base64 "back-end" "tls.key")
  minioTLS=$(get_ssl_certificates_in_base64 "minio" "tls.crt")
  minioKey=$(get_ssl_certificates_in_base64 "minio" "tls.key")

  echo "Install roles and secrets"
  helm upgrade --install --debug \
    "smart-agriculture-roles-secrets" \
    "$BASE_PATH/deploy/infrastructure/roles-secrets" \
    --namespace "$env" \
    --set namespace="$env" \
    --set mqttCA="$mqttCA" \
    --set mqttTLS="$mqttTLS" \
    --set mqttKey="$mqttKey" \
    --set minioTLS="$minioTLS" \
    --set minioKey="$minioKey" \
    --set backEndTLS="$backEndTLS" \
    --set backEndKey="$backEndKey" \
    --set s3aAccessKey="$s3aAccessKey" \
    --set s3aSecretKey="$s3aSecretKey" \
    --set mqttIndexerPassBase64="$(echo "$mqttIndexerPass" | base64)" \
    --set backEndUserPassBase64="$(echo "$backEndUserPass" | base64)"

  echo "Install VerneMQ"
  helm upgrade --install --namespace "$env" "smart-agriculture-vernemq" vernemq/vernemq \
    -f "$BASE_PATH/deploy/infrastructure/vernemq/values.yaml" \
    --set service.loadBalancerIP=$(get_vernemq_ip "$region") \
    --set additionalEnv[0].name=DOCKER_VERNEMQ_USER_indexer \
    --set additionalEnv[0].value="$mqttIndexerPass" \
    --set additionalEnv[1].name=DOCKER_VERNEMQ_USER_device \
    --set additionalEnv[1].value="$mqttDevicePass"

  echo "Install Elasticsearch"
  kubectl apply -f https://download.elastic.co/downloads/eck/1.0.1/all-in-one.yaml
  helm upgrade --install --debug \
    "smart-agriculture-elasticsearch" \
    "$BASE_PATH/deploy/infrastructure/elasticsearch" \
    --namespace "$env" \
    --set namespace="$env"

  echo "Install Minio" # No need of values file for Minio here
  helm upgrade --install --namespace "$env" "smart-agriculture-minio" stable/minio \
    -f "$BASE_PATH/deploy/infrastructure/minio/values.yaml" \
    --set accessKey="$s3aAccessKey" \
    --set secretKey="$s3aSecretKey"
}

function delete_modules_infrastructure(){
  env=$1

  echo "Delete VerneMQ"
  helm del "smart-agriculture-vernemq" --namespace "$env"

  echo "Delete Elasticsearch"
  helm del "smart-agriculture-elasticsearch" --namespace "$env"

  echo "Delete Minio"
  helm del "smart-agriculture-minio" --namespace "$env"

  echo "Delete Roles and Secrets"
  helm del "smart-agriculture-roles-secrets" --namespace "$env"
}