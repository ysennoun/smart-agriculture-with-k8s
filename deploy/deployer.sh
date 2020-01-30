#!/bin/bash

set -e

# PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")


# IMPORTS
. "$BASE_PATH/deploy/infrastructure/deployer_infrastructure.sh"
. "$BASE_PATH/deploy/code/deployer_code.sh"


ACTION=$1
ENVIRONMENT=$2
export PROJECT_ID="your-project-id"
export COMPUTE_ZONE="your-selected-zone"
export COMPUTE_REGION="your-selected-region"
export CONTAINER_REPOSITORY="your docker repository"
export PROJECT_NAME="your project name on gcp"
export DOCKER_VERSION="latest"


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
    install_vernemq "$ENVIRONMENT"

    # Deploy Elasticsearch
    install_elasticsearch "$ENVIRONMENT"

    # Deploy Minio
    install_minio "$ENVIRONMENT"

    # Deploy docker images
    deploy_serverless_docker_images "$CONTAINER_REPOSITORY" "$DOCKER_VERSION"
    deploy_spark_within_docker_image "$CONTAINER_REPOSITORY"
    k8_apiserver_url=$(get_k8_apiserver_url)
    es_nodes=elasticsearch."$ENVIRONMENT".svc.cluster.local
    es_port=9200
    fs_s3a_endpoint=minio."$ENVIRONMENT".svc.cluster.local
    deploy_historical_jobs_docker_images"$CONTAINER_REPOSITORY" "$DOCKER_VERSION" "$k8_apiserver_url" "$es_nodes" "$es_port" "$fs_s3a_endpoint"

    # Deploy applications
    deploy_release_from_templates "smart-agriculture-code" "$ENVIRONMENT" "$CONTAINER_REPOSITORY" "$DOCKER_VERSION"
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