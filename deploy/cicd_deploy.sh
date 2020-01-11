#!/bin/bash

set -e

# PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")


# IMPORTS
. "$BASE_PATH/deploy/infrastructure/infrastructure.sh"
. "$BASE_PATH/deploy/configuration/configuration.sh"

