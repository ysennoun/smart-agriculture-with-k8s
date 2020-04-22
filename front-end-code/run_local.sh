#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")


cd "$BASE_PATH/front-end-code/tests_mock_app"
docker build -f Dockerfile -t api-mock .
docker run -d -p 5000:5000 api-mock
cd "$BASE_PATH/"