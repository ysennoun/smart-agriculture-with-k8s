#!/bin/bash

set -eax

source deploy/cluster/deployer_cluster.sh
source deploy/platform/deployer_platform.sh

## Install k8s clients
install_k8s_clients \
  "$PROJECT_ID" \
  "$CLUSTER_NAME" \
  "$COMPUTE_ZONE"

# Install dependencies
install_e2e_deps

# Install python requirements
install_python_requirements

## Set Docker login
set_docker "$HOSTNAME"

# Run e2e tests
launch_e2e_tests \
  "$ENVIRONMENT" \
  "api" \
  "$API_USER_PASS" \
  "indexer" \
  "$MQTT_INDEXER_PASS"