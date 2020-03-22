#!/bin/bash

set -eax

source deploy/infrastructure/deployer_infrastructure.sh

# Enable APIs
enable_apis
# Activate billing and enable APIs
activate_billing "$PROJECT_ID"

# Create Kubernetes Cluster
create_k8s_cluster "$CLUSTER_NAME"