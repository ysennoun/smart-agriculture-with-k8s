#!/bin/bash

## PARAMETERS
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
BASE_PATH=$(realpath $SCRIPT_DIR/../)

CLUSTER_NAME="k8s-cluster"
COMPUTE_REGION="europe-west1"
COMPUTE_ZONE="europe-west1-b"
MIN_NODES=1
MAX_NODES=15
NUM_NODES=8
MACHINE_TYPE=n1-standard-2
VERNEMQ_RELEASE="vernemq-cluster"
POSTGRES_RELEASE="iot-last-value"
INFLUXDB_RELEASE="iot-timeseries"
REDIS_RELEASE="iot-historical"
K8S_RELEASEE="vernemq-cluster"

## FUNCTIONS
function activate_billing(){
    PROJECT=$1
    echo "Activate billing"
    gcloud config set core/project ${PROJECT}
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
    gcloud beta container clusters create ${CLUSTER_NAME} \
       --addons=HorizontalPodAutoscaling,HttpLoadBalancing,Istio,CloudRun \
       --cluster-version=latest \
       --enable-stackdriver-kubernetes\
       --enable-ip-alias \
       --enable-autorepair \
       --scopes cloud-platform \
       --zone ${COMPUTE_ZONE}  \
       --num-nodes ${NUM_NODES} \
       --machine-type ${MACHINE_TYPE} \
       --enable-autoscaling \
       --min-nodes=${MIN_NODES} \
       --max-nodes=${MAX_NODES}
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
    gcloud beta container clusters delete ${CLUSTER_NAME} --zone ${COMPUTE_ZONE}
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

function add_helm_vernemq_repo(){
    echo "Add Helm VerneMQ repo"
    URL="https://vernemq.github.io/docker-vernemq"
    helm repo add vernemq ${URL}
    helm repo update
}

function install_vernemq(){
    echo "Install VerneMQ"
    helm install vernemq/vernemq --name ${VERNEMQ_RELEASE}  -f ${BASE_PATH}/deploy/infrastructure/vernemq/${VERNEMQ_RELEASE}.yaml
}

function delete_vernemq(){
    echo "Delete VerneMQ"
    helm del --purge ${VERNEMQ_RELEASE}
}

function get_vernemq_status(){
    echo "Get VerneMQ status"
    kubectl exec --namespace default vernemq-cluster-0 /vernemq/bin/vmq-admin cluster show
}

function install_postgresql(){
    echo "Install PostgreSQL"
    DATABASE_USER="userlastvalue"
    DATABASE_NAME="dbiotlastvalue"
    DATABASE_PASSWORD="iotlastvalue1234"
    helm install \
        --name ${POSTGRES_RELEASE} \
        --set global.postgresql.postgresqlPassword=${DATABASE_PASSWORD},global.postgresql.postgresqlUsername=${DATABASE_USER},global.postgresql.postgresqlDatabase=${DATABASE_NAME} \
         stable/postgresql
}

function delete_postgresql(){
    echo "Delete PostgreSQL"
    helm del --purge ${POSTGRES_RELEASE}
}

function install_influxdb(){
    echo "Install Influxdb"
    helm install --name ${INFLUXDB_RELEASE} stable/influxdb
}

function delete_influxdb(){
    echo "Delete Influxdb"
    helm install --name ${INFLUXDB_RELEASE} stable/influxdb
}

function install_redis(){
    echo "Install Redis"
    helm install --name ${REDIS_RELEASE} stable/redis
}

function delete_redis(){
    echo "Delete Redis"
    helm install --name ${REDIS_RELEASE} stable/redis
}