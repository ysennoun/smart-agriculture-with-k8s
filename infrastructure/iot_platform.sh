#!/usr/bin/env bash

set -e

# PARAMETERS
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
BASE_PATH=$(realpath $SCRIPT_DIR/../)


# IMPORTS
. ${BASE_PATH}/infrastructure/script/kubernetes_script.sh
. ${BASE_PATH}/infrastructure/script/vernemq_script.sh
. ${BASE_PATH}/infrastructure/script/postgresql_script.sh


######## FUNCTIONS ########

function install_iot_platform(){
    # Enable APIs
    #enable_apis
    # Activate billing and enable APIs
    #activate_billing ${PROJECT_ID}
    #enable_apis

    # Create Kubernetes Cluster
    #create_k8s_cluster

    # Deploy Knative
    #deploy_knative
    visualize_knative_deployment

    # Deploy VerneMQ
    #add_helm_vernemq_repo
    #install_vernemq

    # Deploy PostgreSQL
    install_postgresql

}

function delete_iot_platform(){
    # Delete PostgreSQL
    delete_postgresql

    # Delete VerneMQ
    #delete_vernemq

    # Delete Kubernetes Cluster
    #delete_k8s_cluster
}


######## MAIN ########

if [[ "$#" -ne 1 ]]; then
    echo "Illegal number of parameters. Run by using parameter 'install' or 'delete'"
    exit 0
fi

VAR1=$1

if [[ "${VAR1}" == "install" ]]
then
    install_iot_platform
elif [[ "${VAR1}" == "delete" ]]
then
    delete_iot_platform
else
    echo "Illegal parameter. Run by using parameter 'install' or 'delete'"
fi