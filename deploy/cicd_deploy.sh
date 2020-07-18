#!/bin/bash

set -eax

source deploy/cluster/deployer_cluster.sh
source deploy/platform/deployer_platform.sh
source deploy/front-end/deployer_front_end.sh

## Install k8s clients
install_k8s_clients \
  "$CLUSTER_NAME" \
  "$COMPUTE_ZONE" \
  "$PROJECT_ID"

## Create Namespace
create_namespace "$ENVIRONMENT"

## Set helm repos
set_helm_repos

# Create Roles and Secrets
deploy_roles_secrets_release \
  "$ENVIRONMENT" \
  "$COMPUTE_REGION" \
  "$S3A_ACCESS_KEY" \
  "$S3A_SECRET_KEY" \
  "$MQTT_INDEXER_PASS" \
  "$MQTT_DEVICE_PASS" \
  "$API_USER_PASS"

# Deploy device management releases
deploy_device_management_releases \
  "$ENVIRONMENT" \
  "$COMPUTE_REGION" \
  "$MQTT_INDEXER_PASS" \
  "$MQTT_DEVICE_PASS"

# Deploy data indexing releases
deploy_data_indexing_releases \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"

# Deploy data processing releases
deploy_data_processing_releases \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION" \
  "$S3A_ACCESS_KEY" \
  "$S3A_SECRET_KEY" \
  "$ES_TRUSTORE_PASS"

# Deploy initialization release
deploy_initialization_release \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"

# Deploy data access releases
deploy_data_access_releases \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION" \
  "$COMPUTE_REGION"

# Deploy front-end release
deploy_front_end_release \
  "$ENVIRONMENT" \
  "$COMPUTE_REGION" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"