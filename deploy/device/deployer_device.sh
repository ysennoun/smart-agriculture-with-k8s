#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

. "$BASE_PATH/deploy/cluster/deployer_cluster.sh"


## FUNCTIONS
function install_device_python_requirements(){
    cd "$BASE_PATH/device/"
    pip install -r requirements.txt
    pip install -r test_requirements.txt
    cd ../../
}

function launch_device_python_unit_tests(){
    # Run unit tests (for python)
    cd "$BASE_PATH/device/"
    python setup.py test
    cd ../
}

function deploy_device_images(){
    region=$1
    containerRepository=$2
    dockerVersion=$3

    # Deploy docker images
    cd "$BASE_PATH/deploy/device/dockerfiles/"
    cp "$BASE_PATH/deploy/cluster/certificates/vernemq/tls.crt" .
    docker build -f Dockerfile-device \
      --build-arg MQTT_HOST_IP=$(get_vernemq_ip "$region") \
      --build-arg MQTT_HOST_PORT="8883" \
      --build-arg MQTT_TOPIC="/iot/farming" \
      --build-arg LOCAL_CERT_PATH="$BASE_PATH/deploy/cluster/certificates/vernemq/tls.crt" \
      -t "$containerRepository/device:$dockerVersion" .
    docker push "$containerRepository/device:$dockerVersion"
    rm -f tls.crt
    cd "$BASE_PATH/"
}