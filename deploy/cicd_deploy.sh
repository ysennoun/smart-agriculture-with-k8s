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
istio_ingress_gateway_ip=$(get_istio_ingress_gateway_ip)

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
k8_apiserver_url=$(get_k8_apiserver_url)
es_nodes=elasticsearch."$ENVIRONMENT".svc.cluster.local
es_port=9200
fs_s3a_endpoint=minio."$ENVIRONMENT".svc.cluster.local
deploy_historical_jobs_docker_images"$CONTAINER_REPOSITORY" "$DOCKER_VERSION" "$k8_apiserver_url" "$es_nodes" "$es_port" "$fs_s3a_endpoint"

# Deploy applications
deploy_release_from_templates "smart-agriculture-code" "$ENVIRONMENT" "$CONTAINER_REPOSITORY" "$VERSION" "$istio_ingress_gateway_ip"
