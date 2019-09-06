#!/usr/bin/env bash

## PARAMETERS
export CLUSTER_NAME="k8s-cluster"
export COMPUTE_REGION="europe-west1"
export COMPUTE_ZONE="europe-west1-b"
export MIN_NODES=1
export MAX_NODES=15
export NUM_NODES=8
export MACHINE_TYPE=n1-standard-2

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
         container.googleapis.com \
         containerregistry.googleapis.com
}

function create_k8s_cluster() {
    echo "Let's create k8s cluster"
    gcloud container clusters create ${CLUSTER_NAME} \
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
    gcloud container clusters delete ${CLUSTER_NAME} --zone ${COMPUTE_ZONE}
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
