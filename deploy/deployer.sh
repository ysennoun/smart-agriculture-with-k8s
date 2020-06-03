#!/bin/bash

set -e

# PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")


# IMPORTS
. "$BASE_PATH/deploy/cluster/deployer_cluster.sh"
. "$BASE_PATH/deploy/infrastructure/deployer_infrastructure.sh"
. "$BASE_PATH/deploy/platform/deployer_platform.sh"


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
MINIO_TRUSTSTORE_PASS="vkM8ssfK5fv4JQ9k"


######## FUNCTIONS ########
usage() {
    echo "Run the script in current shell with . (dot) before. Usage:"
    echo " ." `basename "$0"` "<ACTION> <ENVIRONMENT> "
    echo ""
    echo "ACTION:"
    echo "  - create-certificates <ENVIRONMENT>: create certificates with external statis ip addresses"
    echo "  - delete-external-static-ip-addresses: delete external static ip address"
    echo "  - setup-cluster: create k8s cluster"
    echo "  - deploy-modules <ENVIRONMENT>: deploy all modules (infrastructure, docker images, applications)"
    echo "  - delete-cluster: delete cluster"
    echo "  - delete-namespace <ENVIRONMENT>: delete namespace"
    echo "  - delete-modules <ENVIRONMENT>: delete all modules"
    echo "  - create-device-service-account-and-roles: create device service account and roles"
    echo "  - get-device-service-account-key: get device service account key"
    echo "  - test-unit <ENVIRONMENT>: launch unit tests"
    echo "  - test-e2e <ENVIRONMENT>: launch e2e tests"
    echo "  - get-front-end-ip <ENVIRONMENT>: get front end ip"
}

function create-certificates(){
  # Create certificates
  create_certificates "$ENVIRONMENT" "$COMPUTE_REGION"
}

function delete-external-static-ip-addresses(){
  # Delete external static ip addresses
  deallocate_external_static_ip "$COMPUTE_REGION"
}

function setup-cluster(){
    # Enable APIs
    enable_apis
    # Activate billing and enable APIs
    activate_billing "$PROJECT_ID"

    # Create Kubernetes Cluster
    create_k8s_cluster "$CLUSTER_NAME" "$COMPUTE_ZONE"
}

function deploy-modules(){
    ## Create Namespace
    create_namespace "$ENVIRONMENT"

    ## Set helm repos
    set_helm_repos

    # Create Secrets, Elasticsearch, VerneMQ and Minio clusters
    install_infrastructure \
      "$ENVIRONMENT" \
      "$COMPUTE_REGION" \
      "$S3A_ACCESS_KEY" \
      "$S3A_SECRET_KEY" \
      "$MQTT_INDEXER_PASS" \
      "$MQTT_DEVICE_PASS" \
      "$BACK_END_USER_PASS"

    ## Set Docker login
    set_docker "$HOSTNAME"

    # Deploy Put Jars in Minio image and release And alias in Elasticsearch
    deploy_jars_alias_deployment_image \
      "$ENVIRONMENT" \
      "$CONTAINER_REPOSITORY" \
      "$DOCKER_VERSION"
    deploy_jars_alias_deployment_release \
      "$ENVIRONMENT" \
      "$CONTAINER_REPOSITORY" \
      "$DOCKER_VERSION"

    # Deploy Application images and release
    deploy_application_images \
      "$ENVIRONMENT" \
      "$COMPUTE_REGION" \
      "$CONTAINER_REPOSITORY" \
      "$DOCKER_VERSION"
    deploy_application_release \
      "$ENVIRONMENT" \
      "$COMPUTE_REGION" \
      "$CONTAINER_REPOSITORY" \
      "$DOCKER_VERSION"

    # Deploy Spark and Historical jobs images and release
    deploy_historical_jobs_docker_images \
      "$ENVIRONMENT" \
      "$CONTAINER_REPOSITORY" \
      "$DOCKER_VERSION" \
      "$S3A_ACCESS_KEY" \
      "$S3A_SECRET_KEY" \
      "$ES_TRUSTORE_PASS" \
      "$MINIO_TRUSTSTORE_PASS"
    deploy_historical_jobs_docker_release \
      "$ENVIRONMENT" \
      "$CONTAINER_REPOSITORY" \
      "$DOCKER_VERSION" \
      "$S3A_ACCESS_KEY" \
      "$S3A_SECRET_KEY" \
      "$ES_TRUSTORE_PASS" \
      "$MINIO_TRUSTSTORE_PASS"
}

function delete-cluster(){
    # Delete Kubernetes Cluster
    delete_k8s_cluster "$CLUSTER_NAME" "$COMPUTE_ZONE"
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

function create-device-service-account-and-roles(){
  # Create device service account and roles
  create_device_service_account_and_roles "$PROJECT_NAME"
}

function get-device-service-account-key(){
  # Get device service account key
  get_device_service_account_key "$PROJECT_NAME"
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
    env=$2
    launch_e2e_tests \
      "$env" \
      "back-end" \
      "$BACK_END_USER_PASS" \
      "indexer" \
      "$MQTT_INDEXER_PASS"
}

function get-front-end-ip(){
    # Get front end ip
    env=$2
    echo $(get_front_end_ip "$env")
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