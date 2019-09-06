#!/usr/bin/env bash

## PARAMETERS
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
BASE_PATH=$(realpath $SCRIPT_DIR/../)

RELEASE_NAME="vernemq-cluster"

## FUNCTIONS
function add_helm_vernemq_repo(){
    echo "Add Helm VerneMQ repo"
    URL="https://vernemq.github.io/docker-vernemq"
    helm repo add vernemq ${URL}
    helm repo update
}

function install_vernemq(){
    echo "Install VerneMQ"
    helm install vernemq/vernemq --name ${RELEASE_NAME}  -f ${BASE_PATH}/infrastructure/configuration/vernemq/${RELEASE_NAME}.yaml
}

function delete_vernemq(){
    echo "Delete VerneMQ"
    helm del --purge ${RELEASE_NAME}
}

function get_vernemq_status(){
    echo "Get VerneMQ status"
    kubectl exec --namespace default vernemq-cluster-0 /vernemq/bin/vmq-admin cluster show
}
