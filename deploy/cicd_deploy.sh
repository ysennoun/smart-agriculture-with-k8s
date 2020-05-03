#!/bin/bash

set -eax

source deploy/infrastructure/deployer_infrastructure.sh
source deploy/platform/deployer_platform.sh
source deploy/front-end/deployer_front_end.sh


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
deploy_jars_alias_deployment_image_and_release \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"

# Deploy Application images and release
deploy_application_images_and_release \
  "$ENVIRONMENT" \
  "$COMPUTE_REGION" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"

# Deploy Spark and Historical jobs images and release
deploy_historical_jobs_docker_images_and_release \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION" \
  "$S3A_ACCESS_KEY" \
  "$S3A_SECRET_KEY" \
  "$ES_TRUSTORE_PASS" \
  "$MINIO_TRUSTSTORE_PASS"

# Deploy front-end image and release
deploy_front_end_images_and_release \
  "$ENVIRONMENT" \
  "$COMPUTE_REGION" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"

## Deploy device image
#deploy_device_images \
#  "$COMPUTE_REGION" \
#  "$CONTAINER_REPOSITORY" \
#  "$DOCKER_VERSION"