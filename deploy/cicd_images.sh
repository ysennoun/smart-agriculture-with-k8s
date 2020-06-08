#!/bin/bash

set -eax

source deploy/cluster/deployer_cluster.sh
source deploy/platform/deployer_platform.sh
source deploy/front-end/deployer_front_end.sh
source deploy/device/deployer_device.sh

## Set Docker login
set_docker "$HOSTNAME"

# Deploy platform images
deploy_platform_images \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION" \
  "$S3A_ACCESS_KEY" \
  "$S3A_SECRET_KEY" \
  "$ES_TRUSTORE_PASS" \
  "$MINIO_TRUSTSTORE_PASS"

# Deploy front-end image
deploy_front_end_images \
  "$COMPUTE_REGION" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"

## Deploy device image
#deploy_device_images \
#  "$COMPUTE_REGION" \
#  "$CONTAINER_REPOSITORY" \
#  "$DOCKER_VERSION"