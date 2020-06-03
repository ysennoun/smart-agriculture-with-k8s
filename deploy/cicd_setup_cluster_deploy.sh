#!/bin/bash

set -eax

source deploy/cluster/deployer_cluster.sh

# Enable APIs
enable_apis

# Activate billing and enable APIs
activate_billing "$PROJECT_ID"

# Create Kubernetes Cluster
create_k8s_cluster "$CLUSTER_NAME" "$COMPUTE_ZONE"