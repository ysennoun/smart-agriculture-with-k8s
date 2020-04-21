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
    cd "$BASE_PATH/front-end-code/"
    npm install
    npm run test:unit
    cd ../../
}

function deploy_front_end_images_and_release(){
    namespace=$1
    region=$2
    containerRepository=$3
    dockerVersion=$4

    # Create environment variables file for vue.js
    echo "VUE_APP_BACK_END_URL=https://$(get_back_end_ip "$region"):443" > "$BASE_PATH/front-end-code/.env"

    # Deploy docker images
    cp -r "$BASE_PATH/front-end-code/" "$BASE_PATH/deploy/front-end-code/dockerfiles/front-end-code/"
    cd "$BASE_PATH/deploy/front-end-code/dockerfiles/"
    docker build -f "Dockerfile-front-end" \
      -t "$containerRepository/front-end:$dockerVersion" .
    docker push "$containerRepository/front-end:$dockerVersion"
    cd "$BASE_PATH"
    rm -rf "$BASE_PATH/deploy/front-end-code/dockerfiles/front-end-code/"

    # Deploy release
    helm upgrade --install --debug \
      "smart-agriculture-front-end" \
      "$BASE_PATH/deploy/front-end-code/" \
      --namespace "$namespace" \
      --set namespace="$namespace" \
      --set frontEndIp=$(get_front_end_ip "$region") \
      --set containerRepository="$containerRepository" \
      --set dockerVersion="$dockerVersion"
}

function delete_modules_front_end_code(){
  env=$1
  echo "Delete Modules front end code"
  helm del "smart-agriculture-front-end" --namespace "$env"
}
