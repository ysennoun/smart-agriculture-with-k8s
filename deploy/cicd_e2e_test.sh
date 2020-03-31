#!/bin/bash

set -eax

source deploy/code/deployer_code.sh

# Install python requirements
install_python_requirements

# Run e2e tests
launch_e2e_tests \
  "$ENVIRONMENT" \
  "$CONTAINER_REPOSITORY" \
  "$DOCKER_VERSION" \
  "back-end" \
  "$BACK_END_USER_PASS" \
  "indexer" \
  "$MQTT_INDEXER_PASS"