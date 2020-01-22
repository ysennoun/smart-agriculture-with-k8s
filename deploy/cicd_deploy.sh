#!/bin/bash

set -eax

source deploy/infrastructure/deployer_infrastructure.sh
source deploy/code/deployer_code.sh


# Enable APIs
enable_apis
# Activate billing and enable APIs
activate_billing "$PROJECT_ID"
enable_apis

# Create Kubernetes Cluster
create_k8s_cluster

# Deploy Knative
deploy_knative
visualize_knative_deployment
export_istio_ingress_gateway_ip

# Deploy VerneMQ
add_helm_vernemq_repo
install_vernemq

# Deploy Elasticsearch
install_elasticsearch

# Deploy Minio
install_minio

# Deploy docker images
deploy_serverless_docker_images "$CONTAINER_REPOSITORY" "$DOCKER_VERSION"
deploy_spark_within_docker_image "$CONTAINER_REPOSITORY"
deploy_historical_jobs_docker_images"$CONTAINER_REPOSITORY" "$DOCKER_VERSION" "-" "-" "-" "-" "-"

# Deploy applications
deploy_release_from_templates "smart-agriculture-code" "$ENVIRONMENT" "$CONTAINER_REPOSITORY" "$VERSION"
