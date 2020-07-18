#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

MIN_NODES=1
MAX_NODES=3
NUM_NODES=1
MACHINE_TYPE=n1-standard-4

## FUNCTIONS
function activate_billing(){
  projectId=$1
  echo "Activate billing"
  ## cannot be done through terraform
  gcloud config set core/project "$projectId"
}

function enable_apis(){
  echo "Activate APIs"
  projectId=$1

  cd "$BASE_PATH/deploy/cluster/terraform/apis/"
  echo "project_id = \"$projectId\"" > terraform.tfvars
  terraform init && terraform plan && terraform apply -auto-approve
  cd "$BASE_PATH"
}

function create_docker_registries(){
  echo "Create Docker Registries"
  projectId=$1

  cd "$BASE_PATH/deploy/cluster/terraform/docker-registries/"
  echo "project_id = \"$projectId\"" > terraform.tfvars
  terraform init && terraform plan && terraform apply -auto-approve
  cd "$BASE_PATH"
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
  create_ssl_certificates "api" "api.$env.svc.cluster.local" $(get_api_ip "$region")
  create_ssl_certificates "vernemq" "device-management-vernemq.$env.svc.cluster.local" $(get_vernemq_ip "$region")
  create_ssl_certificates "minio" "data-processing-minio.$env.svc.cluster.local"
}

function create_k8s_cluster() {
  echo "Let's create k8s cluster"
  projectId=$1
  clusterName=$2
  computeRegion=$3
  computeZone=$4

  cd "$BASE_PATH/deploy/cluster/terraform/gke/"
  echo "project_id = \"$projectId\"" >> terraform.tfvars
  echo "cluster_name = \"$clusterName\"" >> terraform.tfvars
  echo "region = \"$computeRegion\"" >> terraform.tfvars
  echo "zone = \"$computeZone\"" >> terraform.tfvars
  terraform init && terraform plan && terraform apply -auto-approve
  cd "$BASE_PATH"

  ## Get credentials for kubectl
  gcloud container clusters get-credentials "$clusterName" --zone="$computeZone" --project="$projectId"

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
  projectId=$1
  clusterName=$2
  computeRegion=$3
  computeZone=$4

  cd "$BASE_PATH/deploy/cluster/terraform/gke/"
  echo "project_id = \"$projectId\"" >> terraform.tfvars
  echo "cluster_name = \"$clusterName\"" >> terraform.tfvars
  echo "region = \"$computeRegion\"" >> terraform.tfvars
  echo "zone = \"$computeZone\"" >> terraform.tfvars
  terraform destroy -auto-approve
  cd "$BASE_PATH"
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
  gcloud compute addresses create api-ip --region "$region"
  gcloud compute addresses create front-end-ip --region "$region"
}

function deallocate_external_static_ip(){
  region=$1
  gcloud compute addresses delete vernemq-ip --region "$region" --quiet
  gcloud compute addresses delete api-ip --region "$region" --quiet
  gcloud compute addresses delete front-end-ip --region "$region" --quiet
}

function get_vernemq_ip(){
  region=$1
  echo "$(gcloud compute addresses describe vernemq-ip --region "$region" | head -1 | awk '{print $2}')"
}

function get_api_ip(){
  region=$1
  echo "$(gcloud compute addresses describe api-ip --region "$region" | head -1 | awk '{print $2}')"
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
