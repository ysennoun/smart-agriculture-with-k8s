#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

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

function create_certificates(){
  env=$1
  region=$2

  echo "Create external ip"
  allocate_external_static_ip "$region"

  echo "Create certificates"
  create_ssl_certificates "back-end" "back-end.$env.svc.cluster.local" $(get_back_end_ip "$region")
  create_ssl_certificates "vernemq" "smart-agriculture-vernemq.$env.svc.cluster.local" $(get_vernemq_ip "$region")
  create_ssl_certificates "minio" "smart-agriculture-minio.$env.svc.cluster.local"
}

function create_k8s_cluster() {
  echo "Let's create k8s cluster"
  clusterName=$1
  computeZone=$2
  gcloud beta container clusters create "$clusterName" \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing \
    --machine-type="$MACHINE_TYPE" \
    --cluster-version=latest --zone="$computeZone" \
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
  computeZone=$2
  gcloud beta container clusters delete "$clusterName" --zone "$computeZone" --quiet
  echo "End deletion"
}

function create_device_service_account_and_roles(){
  projectId=$1
  gcloud iam service-accounts create "smart-agriculture-devices" \
     --description "Service Account for devices to pull docker images" \
     --display-name "smart-agriculture-devices"
  gcloud projects add-iam-policy-binding "$projectId" \
      --member "serviceAccount:smart-agriculture-devices@$projectId.iam.gserviceaccount.com" \
      --role roles/storage.objectViewer
}

function get_device_service_account_key(){
  projectId=$1
  gcloud iam service-accounts keys create ~/key.json \
      --iam-account "smart-agriculture-devices@$projectId.iam.gserviceaccount.com"
  echo $(cat ~/key.json)
}

function allocate_external_static_ip(){
  region=$1
  gcloud compute addresses create vernemq-ip --region "$region"
  gcloud compute addresses create back-end-ip --region "$region"
  gcloud compute addresses create front-end-ip --region "$region"
}

function deallocate_external_static_ip(){
  region=$1
  gcloud compute addresses delete vernemq-ip --region "$region" --quiet
  gcloud compute addresses delete back-end-ip --region "$region" --quiet
  gcloud compute addresses delete front-end-ip --region "$region" --quiet
}

function get_vernemq_ip(){
  region=$1
  echo "$(gcloud compute addresses describe vernemq-ip --region "$region" | head -1 | awk '{print $2}')"
}

function get_back_end_ip(){
  region=$1
  echo "$(gcloud compute addresses describe back-end-ip --region "$region" | head -1 | awk '{print $2}')"
}

function get_front_end_ip(){
  region=$1
  echo "$(gcloud compute addresses describe front-end-ip --region "$region" | head -1 | awk '{print $2}')"
}

function create_ssl_certificates(){
  server=$1
  application=$2
  optionalIpAddress=$3

  cd "$BASE_PATH/deploy/cluster/certificates/$server"
  openssl genrsa -out ca.key 2048
  openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
      -subj "/C=FR/O=France/OU=smart/CN=$application"

  openssl genrsa -out tls.key 2048
  openssl req -new -out tls.csr -key tls.key \
      -subj "/C=FR/O=France/OU=smart/CN=$application"

  if [ ! -z "$optionalIpAddress" ]; then
    cert_cnf=$(cat cert.tmp | sed -e "s/APP_TO_REPLACE/$application/g" | sed -e "s/0.0.0.0/$optionalIpAddress/g")
  else
    cert_cnf=$(cat cert.tmp | sed -e "s/APP_TO_REPLACE/$application/g")
  fi
  echo "$cert_cnf" > cert.cnf

  if grep -qF "[ alt_names ]" cert.cnf;then
     # Found alternatives dns or/and ip
     openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -extensions req_ext -extfile cert.cnf \
     -out tls.crt -days 3650
  else
     openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -extfile cert.cnf -out tls.crt -days 3650
  fi

  rm -f ca.key ca.srl tls.csr

  cd "$BASE_PATH"
}

function get_ssl_certificates_in_base64(){
  server=$1
  file=$2
  echo $(cat "$BASE_PATH/deploy/cluster/certificates/$server/$file" | base64 | tr -d '\n')
}
