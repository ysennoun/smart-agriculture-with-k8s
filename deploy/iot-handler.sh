#!/bin/bash

set -e

# PARAMETERS
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
BASE_PATH=$(realpath $SCRIPT_DIR/../)


# IMPORTS
. ${BASE_PATH}/deploy/infrastructure/infrastructure.sh
. ${BASE_PATH}/deploy/configuration/configuration.sh


ACTION=$1

######## FUNCTIONS ########
usage() {
    echo "Run the script in current shell with . (dot) before. Usage:"
    echo " ." `basename "$0"` "<ACTION> "
    echo ""
    echo "ACTION:"
    echo "  - deploy-all: deploy all modules (infrastructure, docker images, applications)"
    echo "  - delete-all: delete all modules"
    echo "  - test-unit: launch unit tests"
}

function deploy-all(){
    # Enable APIs
    enable_apis
    # Activate billing and enable APIs
    activate_billing ${PROJECT_ID}
    enable_apis

    # Create Kubernetes Cluster
    create_k8s_cluster

    # Deploy Knative
    deploy_knative
    visualize_knative_deployment

    # Deploy VerneMQ
    add_helm_vernemq_repo
    install_vernemq

    # Deploy PostgreSQL
    install_postgresql

}

function delete-all(){
    # Delete Kubernetes Cluster
    delete_k8s_cluster
}


######## MAIN ########

fn_exists() {
  [[ `type -t $1`"" == 'function' ]]
}

main() {

    if [[ -n "${ACTION}" ]]; then
        echo
    else
        usage
        exit 1
    fi

    if ! fn_exists ${ACTION}; then
        echo "Error: ${ACTION} is not a valid ACTION"
        usage
        exit 2
    fi

    # Execute action
    ${ACTION} "$@"
}

main "$@"