#!/bin/bash

set -eax

source deploy/infrastructure/deployer_infrastructure.sh
source deploy/platform/deployer_platform.sh
source deploy/front-end/deployer_front_end.sh
source deploy/device/deployer_device.sh

## Set Docker login
set_docker "$HOSTNAME"

# Deploy Put Jars in Minio image
deploy_jars_alias_deployment_image \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"

# Deploy Application images
deploy_application_images \
  "$ENVIRONMENT" \
  "$COMPUTE_REGION" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"

# Deploy Spark and Historical jobs images
deploy_historical_jobs_docker_images \
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

# Deploy device image
deploy_device_images \
  "$COMPUTE_REGION" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"