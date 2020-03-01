#!/bin/bash

set -e

# PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")


# IMPORTS
. "$BASE_PATH/deploy/certificates/deployer_certificates.sh"
. "$BASE_PATH/deploy/infrastructure/deployer_infrastructure.sh"
. "$BASE_PATH/deploy/code/deployer_code.sh"


ACTION=$1
ENVIRONMENT=$2
export PROJECT_ID="ysennoun-iot" #"your-project-id"
export COMPUTE_ZONE="europe-west1-b" #"your-selected-zone"
export COMPUTE_REGION="europe-west1" #"your-selected-region"
export HOSTNAME="eu.gcr.io"
export CONTAINER_REPOSITORY="$HOSTNAME/$PROJECT_ID" #"your docker repository"
export PROJECT_NAME="ysennoun-iot" #"your project name on gcp"
export DOCKER_VERSION="latest"
CLUSTER_NAME="smart-agriculture-cluster"
INFRASTRUCTURE_RELEASE="smart-agriculture"


######## FUNCTIONS ########
usage() {
    echo "Run the script in current shell with . (dot) before. Usage:"
    echo " ." `basename "$0"` "<ACTION> <ENVIRONMENT> "
    echo ""
    echo "ACTION:"
    echo "  - setup-cluster: create k8s cluster"
    echo "  - create-certificates <ENVIRONMENT>: create certificates for environment"
    echo "  - deploy-modules <ENVIRONMENT>: deploy all modules (infrastructure, docker images, applications)"
    echo "  - delete-cluster: delete cluster"
    echo "  - delete-modules: delete cluster"
    echo "  - test-unit <ENVIRONMENT>: launch unit tests"
    echo "  - test-e2e <ENVIRONMENT>: launch e2e tests"
}

function setup-cluster(){
    # Enable APIs
    enable_apis
    # Activate billing and enable APIs
    activate_billing ${PROJECT_ID}

    # Create Kubernetes Cluster
    create_k8s_cluster "$CLUSTER_NAME"
}

function create-certificates(){
  echo "Create certificates"
  create_ssl_certificates "vernemq" "$INFRASTRUCTURE_RELEASE-vernemq.$ENVIRONMENT.svc.cluster.local"
  create_ssl_certificates "elasticsearch" "$INFRASTRUCTURE_RELEASE-elasticsearch-es-http"
}

function deploy-modules(){
    ## Create Namespace
    create_namespace "$ENVIRONMENT"

    ## Set helm repos
    set_helm_repos

    ## Create Namespace, Elasticsearch, VerneMQ and Minio clusters
    install_infrastructure "infrastructure" "$ENVIRONMENT" "$INFRASTRUCTURE_RELEASE"

    ## Deploy Knative
    deploy_knative
    visualize_knative_deployment
    echo $(get_istio_ingress_gateway_ip)

    ## Set Docker login
    set_docker "$HOSTNAME"

    ## Deploy docker images
    deploy_serverless_docker_images "$CONTAINER_REPOSITORY" "$DOCKER_VERSION"
    deploy_spark_within_docker_image "$CONTAINER_REPOSITORY"
    k8_apiserver_url=$(get_k8_apiserver_url)
    es_nodes=elasticsearch-master
    es_port=9200
    fs_s3a_endpoint="$INFRASTRUCTURE_RELEASE"-minio:9000
    deploy_historical_jobs_docker_images "$ENVIRONMENT" "$CONTAINER_REPOSITORY" "$DOCKER_VERSION" "$k8_apiserver_url" "$es_nodes" "$es_port" "$fs_s3a_endpoint"

    # Deploy applications
    deploy_release_from_templates "code" "$ENVIRONMENT" "$INFRASTRUCTURE_RELEASE" "$CONTAINER_REPOSITORY" "$DOCKER_VERSION"
}

function delete-cluster(){
    # Delete Kubernetes Cluster
    delete_k8s_cluster "$CLUSTER_NAME"
}

function gen(){
  create_ssl_certificates "dev" "elasticsearch" "smart-agriculture-elasticsearch"
  get_ssl_certificates_in_base64 "elasticsearch" "tls.key"
}

function delete-modules(){
    # Delete Namespace
    delete_namespace "$ENVIRONMENT"
}

function test-unit(){
    # Install python requirements
    install_python_requirements

    # Run python and spark unit tests
    launch_python_unit_tests
    launch_spark_unit_tests
}

function test-e2e(){
    # Run e2e tests
    export ENVIRONMENT=$2
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