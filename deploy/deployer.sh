#!/bin/bash

set -e

# PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")


# IMPORTS
. "$BASE_PATH/deploy/infrastructure/infrastructure.sh"
. "$BASE_PATH/deploy/configuration/configuration.sh"


ACTION=$1
ENVIRONMENT=$2
export PROJECT_ID="your-project-id"
export COMPUTE_ZONE="your-selected-zone"
export COMPUTE_REGION="your-selected-region"
export CONTAINER_REPOSITORY="your docker repository"
export PROJECT_NAME="your project name on gcp"
export VERSION="latest"


######## FUNCTIONS ########
usage() {
    echo "Run the script in current shell with . (dot) before. Usage:"
    echo " ." `basename "$0"` "<ACTION> <ENVIRONMENT> "
    echo ""
    echo "ACTION:"
    echo "  - deploy-all <ENVIRONMENT>: deploy all modules (infrastructure, docker images, applications)"
    echo "  - delete-all <ENVIRONMENT>: delete all modules"
    echo "  - test-unit <ENVIRONMENT>: launch unit tests"
    echo "  - test-e2e <ENVIRONMENT>: launch e2e tests"
}

function install_deps() {
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates-java jq realpath zip
    apt-get install -y openjdk-8-jdk maven
    update-ca-certificates -f
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
    export_istio_ingress_gateway_ip

    # Deploy VerneMQ
    add_helm_vernemq_repo
    install_vernemq

    # Deploy Elasticsearch
    install_elasticsearch

    # Deploy Minio
    install_minio

    # Deploy docker images
    deploy_api_image
    deploy_storage_image
    deploy_connector_image
    deploy_notification_image

    # Deploy applications
    deploy_api_application
    deploy_storage_application
    deploy_connector_application
    deploy_notification_application
    deploy_ingress_for_kn_function_api
}

function delete-all(){
    # Delete Kubernetes Cluster
    delete_k8s_cluster
}

function test-unit(){
    # Install python requirements
    install_python_requirements

    # Run python and spark unit tests
    launch_python_unit_tests
    launch_spark_unit_tests
}

function test-2e2(){
    # Run e2e tests
    cd "$BASE_PATH/code/features/"
    behave
    cd ../../
}

fn_exists() {
  [[ `type -t $1`"" == 'function' ]]
}

main() {

    if [[ -n "$ACTION" ]]; then
        echo
    else
        usage
        exit 1
    fi

    if ! fn_exists "$ACTION"; then
        echo "Error: $ACTION is not a valid ACTION"
        usage
        exit 2
    fi

    # Execute action
    ${ACTION} "$@"
}

main "$@"