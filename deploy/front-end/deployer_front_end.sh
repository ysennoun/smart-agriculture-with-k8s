#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

. "$BASE_PATH/deploy/cluster/deployer_cluster.sh"

## FUNCTIONS
function install_vue_deps() {
    apk update
    apk add nodejs npm
}

function launch_vue_unit_tests(){
    # Run unit tests (for vue.js)
    cd "$BASE_PATH/front-end/"
    npm install
    npm run test:unit
    cd ../../
}

function deploy_front_end_images(){
    region=$1
    containerRepository=$2
    dockerVersion=$3

    # Create environment variables file for vue.js
    echo "VUE_APP_BACK_END_URL=https://$(get_back_end_ip "$region"):443" > "$BASE_PATH/front-end/.env"

    # Deploy docker images
    cp -r "$BASE_PATH/front-end/" "$BASE_PATH/deploy/front-end/dockerfiles/front-end/"
    cd "$BASE_PATH/deploy/front-end/dockerfiles/"
    docker build -f "Dockerfile" \
      -t "$containerRepository/front-end:$dockerVersion" .
    docker push "$containerRepository/front-end:$dockerVersion"
    cd "$BASE_PATH"
    rm -rf "$BASE_PATH/deploy/front-end/dockerfiles/front-end/"
}

function deploy_front_end_release(){
    namespace=$1
    region=$2
    containerRepository=$3
    dockerVersion=$4

    # Deploy release
    helm upgrade --install --debug \
      "smart-agriculture-front-end" \
      "$BASE_PATH/deploy/front-end/" \
      --namespace "$namespace" \
      --set namespace="$namespace" \
      --set frontEndIp=$(get_front_end_ip "$region") \
      --set containerRepository="$containerRepository" \
      --set dockerVersion="$dockerVersion"
}

function delete_modules_front_end(){
  env=$1
  echo "Delete Modules front end code"
  helm del "smart-agriculture-front-end" --namespace "$env"
}
