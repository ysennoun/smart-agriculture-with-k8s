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
export COMPUTE_ZONE="europe-west3-b" #"your-selected-zone"
export COMPUTE_REGION="europe-west3" #"your-selected-region"
export HOSTNAME="eu.gcr.io"
export CONTAINER_REPOSITORY="$HOSTNAME/$PROJECT_ID" #"your docker repository"
export PROJECT_NAME="ysennoun-iot" #"your project name on gcp"
export DOCKER_VERSION="latest"
CLUSTER_NAME="smart-agriculture-cluster"
S3A_ACCESS_KEY="AKIAIOSFODNN7EXAMPLE"
S3A_SECRET_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
MQTT_INDEXER_PASS="3ywbCs2uB4"
MQTT_DEVICE_PASS="9Fex2nqdqe"
BACK_END_USER_PASS="4hxGaN34KQ"
ES_TRUSTORE_PASS="ChI2OfIpGuq0be5X"


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
    echo "  - delete-namespace <ENVIRONMENT>: delete namespace"
    echo "  - delete-modules <ENVIRONMENT>: delete all modules"
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
  create_ssl_certificates "back_end" "back-end.$ENVIRONMENT.svc.cluster.local"
  create_ssl_certificates "vernemq" "smart-agriculture-vernemq.$ENVIRONMENT.svc.cluster.local"
  create_ssl_certificates "minio" "smart-agriculture-minio.$ENVIRONMENT.svc.cluster.local"
}

function deploy-modules(){
    ## Create Namespace
    create_namespace "$ENVIRONMENT"

    ## Set helm repos
    set_helm_repos

    # Create Secrets, Elasticsearch, VerneMQ and Minio clusters
    install_infrastructure \
      "$ENVIRONMENT" \
      "$S3A_ACCESS_KEY" \
      "$S3A_SECRET_KEY" \
      "$MQTT_INDEXER_PASS" \
      "$MQTT_DEVICE_PASS" \
      "$BACK_END_USER_PASS"

    ## Set Docker login
    set_docker "$HOSTNAME"

    # Deploy Put Jars in Minio image and release And alias in Elasticsearch
    deploy_jars_alias_deployment_image_and_release \
      "$ENVIRONMENT" \
      "$CONTAINER_REPOSITORY" \
      "$DOCKER_VERSION"

    # Deploy Application images and release
    deploy_application_images_and_release \
          "$ENVIRONMENT" \
          "$CONTAINER_REPOSITORY"  \
          "$DOCKER_VERSION"

    # Deploy Spark and Historical jobs images and release
    k8_apiserver_url=$(get_k8_apiserver_url)
    deploy_historical_jobs_docker_images_and_release \
      "$ENVIRONMENT" \
      "$CONTAINER_REPOSITORY" \
      "$DOCKER_VERSION" \
      "$k8_apiserver_url" \
      "$S3A_ACCESS_KEY" \
      "$S3A_SECRET_KEY" \
      "$ES_TRUSTORE_PASS"
}

function delete-cluster(){
    # Delete Kubernetes Cluster
    delete_k8s_cluster "$CLUSTER_NAME"
}

function delete-namespace(){
    # Delete Namespace
    delete_namespace "$ENVIRONMENT"
}

function delete-modules(){
    # Delete Modules
    delete_modules_code "$ENVIRONMENT"
    delete_modules_infrastructure "$ENVIRONMENT"
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