#!/bin/bash

set -eax

source deploy/cluster/deployer_cluster.sh

# Enable APIs
enable_apis "$PROJECT_ID"

# Activate billing and enable APIs
activate_billing "$PROJECT_ID"

create_docker_registries "$PROJECT_ID"

# Create Kubernetes Cluster
create_k8s_cluster "$PROJECT_ID" "$CLUSTER_NAME" "$COMPUTE_REGION"  "$COMPUTE_ZONE"