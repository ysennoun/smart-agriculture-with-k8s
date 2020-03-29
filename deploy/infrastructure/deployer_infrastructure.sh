#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

. "$BASE_PATH/deploy/certificates/deployer_certificates.sh"

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
  s3aAccessKey=$2
  s3aSecretKey=$3
  mqttIndexerPass=$4
  mqttDevicePass=$5
  backEndUserPass=$6

  echo "Install VerneMQ with LoadBalancer and TLS disabled"
  helm upgrade --install --namespace "$env" "smart-agriculture-vernemq" vernemq/vernemq \
    -f "$BASE_PATH/deploy/infrastructure/configuration/vernemq-tls-disabed.yaml"

  echo "Retrieve VerneMQ LoadBalancer External IP address to update with TLS"
  vernemqExternalIp=$(get_vernemq_external_ip "$env")
  refresh_vernemq_ssl_certificates "$env" "$vernemqExternalIp"

  echo "Get certificates with new certificate for vernemq"
  mqttCA=$(get_ssl_certificates_in_base64 "vernemq" "ca.crt")
  mqttTLS=$(get_ssl_certificates_in_base64 "vernemq" "tls.crt")
  mqttKey=$(get_ssl_certificates_in_base64 "vernemq" "tls.key")
  backEndTLS=$(get_ssl_certificates_in_base64 "back_end" "tls.crt")
  backEndKey=$(get_ssl_certificates_in_base64 "back_end" "tls.key")
  #minioTLS=$(get_ssl_certificates_in_base64 "minio" "tls.crt")
  #minioKey=$(get_ssl_certificates_in_base64 "minio" "tls.key")

  echo "Install Secrets, Elasticsearch"
  kubectl apply -f https://download.elastic.co/downloads/eck/1.0.1/all-in-one.yaml
  helm upgrade --install --debug \
    "infra-secrets-and-elasticsearch" \
    "$BASE_PATH/deploy/infrastructure" \
    --namespace "$env" \
    --set namespace="$env" \
    --set mqttCA="$mqttCA" \
    --set mqttTLS="$mqttTLS" \
    --set mqttKey="$mqttKey" \
    --set backEndTLS="$backEndTLS" \
    --set backEndKey="$backEndKey" \
    --set s3aAccessKey="$s3aAccessKey" \
    --set s3aSecretKey="$s3aSecretKey" \
    --set mqttIndexerPassBase64="$(echo "$mqttIndexerPass" | base64)" \
    --set backEndUserPassBase64="$(echo "$backEndUserPass" | base64)"
   #--set minioTLS="$minioTLS" \
    #--set minioKey="$minioKey" \

  echo "Upgrade VerneMQ with new SSL certificate and new users"
  helm upgrade --install --namespace "$env" "smart-agriculture-vernemq" vernemq/vernemq \
    -f "$BASE_PATH/deploy/infrastructure/configuration/vernemq-tls-enabed.yaml" \
    --set additionalEnv[0].name=DOCKER_VERNEMQ_USER_indexer \
    --set additionalEnv[0].value="$mqttIndexerPass" \
    --set additionalEnv[1].name=DOCKER_VERNEMQ_USER_device \
    --set additionalEnv[1].value="$mqttDevicePass"

  echo "Install Minio"
  helm upgrade --install --namespace "$env" "smart-agriculture-minio" \
    -f "$BASE_PATH/deploy/infrastructure/configuration/minio.yaml" \
    --set accessKey="$s3aAccessKey" \
    --set secretKey="$s3aSecretKey" \
   stable/minio
}

function delete_modules_infrastructure(){
  env=$1

  echo "Delete Secrets and Elasticsearch"
  helm del "infra-secrets-and-elasticsearch" --namespace "$env"

  echo "Delete Minio"
  helm del "smart-agriculture-minio" --namespace "$env"

  echo "Delete VerneMQ"
  helm del "smart-agriculture-vernemq" --namespace "$env"
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
  echo $(cat "$BASE_PATH/deploy/certificates/$server/$file" | base64 | tr -d '\n')
}

function get_vernemq_external_ip(){
  env=$1
  timeout=600 # 10 minutes
  isExternalIpFound=false
  while [ $timeout -gt 0 ]
  do
    externalIp=$(kubectl get service -n "$env" smart-agriculture-vernemq -o  jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$externalIp" ]
    then
          # "External Ip is pending"
          sleep 10
          timeout=`expr $timeout - 10`
    else
          isExternalIpFound=true
          break
    fi
  done

  if [ "$isExternalIpFound" = false ] ; then
    echo "External Ip for LoadBalancer can not be found"
    exit 1
  fi
  echo "$externalIp"
}

function refresh_vernemq_ssl_certificates(){
  env=$1
  externalIp=$2
  create_ssl_certificates "vernemq" "smart-agriculture-vernemq.$env.svc.cluster.local" "$externalIp"
}