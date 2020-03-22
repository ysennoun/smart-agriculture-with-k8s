#!/bin/bash

set -eax

source deploy/infrastructure/deployer_infrastructure.sh
source deploy/code/deployer_code.sh


## Create Namespace
create_namespace "$ENVIRONMENT"

## Set helm repos
set_helm_repos

## Create Secrets, Elasticsearch, VerneMQ and Minio clusters
install_infrastructure \
  "$ENVIRONMENT" \
  "$S3A_ACCESS_KEY" \
  "$S3A_SECRET_KEY" \
  "$MQTT_INDEXER_PASS" \
  "$MQTT_NOTIFIER_PASS" \
  "$MQTT_DEVICE_PASS"

## Set Docker login
set_docker "$HOSTNAME"

## Deploy Put Jars in Minio image and release And alias in Elasticsearch
deploy_jars_alias_deployment_image_and_release \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION"

# Deploy Application images and release
deploy_application_images_and_release \
      "$ENVIRONMENT" \
      "$CONTAINER_REPOSITORY"  \
      "$DOCKER_VERSION"

## Deploy Spark and Historical jobs images and release
k8_apiserver_url=$(get_k8_apiserver_url)
deploy_historical_jobs_docker_images_and_release \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION" \
  "$k8_apiserver_url" \
  "$S3A_ACCESS_KEY" \
  "$S3A_SECRET_KEY" \
  "$ES_TRUSTORE_PASS"
