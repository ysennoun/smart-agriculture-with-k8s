#!/bin/bash

set -eax

source deploy/infrastructure/deployer_infrastructure.sh
source deploy/code/deployer_platform.sh

# Install python requirements
install_python_requirements

## Set Docker login
set_docker "$HOSTNAME"

# Run e2e tests
launch_e2e_tests \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION" \
  "back-end" \
  "$BACK_END_USER_PASS" \
  "indexer" \
  "$MQTT_INDEXER_PASS"