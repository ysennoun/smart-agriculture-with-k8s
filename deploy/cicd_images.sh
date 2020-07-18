#!/bin/bash

set -eax

source deploy/cluster/deployer_cluster.sh
source deploy/platform/deployer_platform.sh
source deploy/front-end/deployer_front_end.sh
source deploy/device/deployer_device.sh

## Install k8s clients
install_k8s_clients \
  "$CLUSTER_NAME" \
  "$COMPUTE_ZONE" \
  "$PROJECT_ID"

## Set Docker login
set_docker "$HOSTNAME"

# Deploy platform images
deploy_platform_images \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"

## Deploy front-end image
deploy_front_end_images \
  "$COMPUTE_REGION" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"

# Deploy device image
deploy_device_images \
  "$COMPUTE_REGION" \
  "$CONTAINER_REPOSITORY" \
  "latest"