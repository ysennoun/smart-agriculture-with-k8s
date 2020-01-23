#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

INCOMING_ALIAS="smart-agriculture"
PREPARED_DATA_PATH="s3://bucket/prepared/"


function install_python_requirements(){
    cd "$BASE_PATH/code/serverless/"
    pip install -r requirements.txt
    pip install -r test_requirements.txt
    cd ../../
}

function install_deps() {
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates-java jq realpath zip
    apt-get install -y openjdk-8-jdk maven
    update-ca-certificates -f
}

function launch_python_unit_tests(){
    # Run unit tests (for python)
    cd "$BASE_PATH/code/serverless/"
    python setup.py test
    cd ../../
}

function launch_spark_unit_tests(){
    # Run unit tests (for spark scala)
    cd "$BASE_PATH/code/historical-jobs/"
    mvn clean test
    cd ../../
}

function launch_e2e_tests(){
    # Run e2e tests
    cd "$BASE_PATH/code/features/"
    behave
    cd ../../
}

function deploy_serverless_docker_images(){
    container_repository=$1
    docker_version=$2

    docker build -f "$BASE_PATH/deploy/code/dockerfiles/serverless/api/Dockerfile-api" \
      -t "$container_repository/api:$docker_version" .
    docker push "$container_repository/api:$docker_version"

    docker build -f "$BASE_PATH/deploy/code/dockerfiles/serverless/indexer/Dockerfile-indexer" \
      -t "$container_repository/indexer:$docker_version" .
    docker push "$container_repository/indexer:$docker_version"

    docker build -f "$BASE_PATH/deploy/code/dockerfiles/serverless/mqtt/Dockerfile-mqtt-client" \
      -t "$container_repository/mqtt-client:$docker_version" .
    docker push "$container_repository/mqtt-client:$docker_version"

    docker build -f "$BASE_PATH/deploy/code/dockerfiles/serverless/notification/Dockerfile-notification" \
      -t "$container_repository/notification:$docker_version" .
    docker push "$container_repository/notification:$docker_version"
}

function deploy_spark_within_docker_image(){
    container_repository=$1
    wget https://apache.mirrors.benatherton.com/spark/spark-2.4.4/spark-2.4.4.tgz
    tar -zxvf spark-2.4.4.tgz
    cd spark-2.4.4/
    ./bin/docker-image-tool.sh -r "$container_repository" -t "spark-on-docker:2.4.4" build
    ./ls a-lbin/docker-image-tool.sh -r "$container_repository" -t "spark-on-docker:2.4.4" push
    cd ..
    rm -f spark-2.4.4.tgz
    rm -rf spark-2.4.4/
}

function deploy_historical_jobs_docker_images(){
    container_repository=$1
    docker_version=s2
    k8_apiserver_url=$3
    es_nodes=$4
    es_port=$5
    fs_s3a_endpoint=$6
    incoming_alias=$INCOMING_ALIAS
    prepared_data_path=$PREPARED_DATA_PATH

    docker build \
      --build-arg CONTAINER_REPOSITORY="$container_repository" \
      --build-arg K8S_APISERVER_URL="$k8_apiserver_url" \
      --build-arg ES_NODES="$es_nodes" \
      --build-arg ES_PORT="$es_port" \
      --build-arg FS_S3A_ENDPOINT="$fs_s3a_endpoint" \
      --build-arg INCOMING_ALIAS="$incoming_alias" \
      --build-arg PREPARED_DATA_PATH="$prepared_data_path" \
      -f "$BASE_PATH/deploy/code/dockerfiles/historical-jobs/Dockerfile-es-to-parquet" \
      -t "$container_repository/spark-es-to-parquet:$docker_version" .
    docker push "$container_repository/spark-es-to-parquet:$docker_version"

    docker build \
      --build-arg CONTAINER_REPOSITORY="$container_repository" \
      --build-arg K8S_APISERVER_URL="$k8_apiserver_url" \
      --build-arg ES_NODES="$es_nodes" \
      --build-arg ES_PORT="$es_port" \
      --build-arg FS_S3A_ENDPOINT="$fs_s3a_endpoint" \
      --build-arg INCOMING_ALIAS="$incoming_alias" \
      --build-arg PREPARED_DATA_PATH="$prepared_data_path" \
      -f "$BASE_PATH/deploy/code/dockerfiles/historical-jobs/Dockerfile-average-point-per-device-and-date" \
      -t "$container_repository/spark-average-point-per-device-and-date:$docker_version" .
    docker push "$container_repository/spark-average-point-per-device-and-date:$docker_version"
}

function deploy_release_from_templates(){
  release=$1
  namespace=$2
  container_repository=$3
  docker_version=$4
  istio_ingress_gateway_ip_address=$5

  helm install --debug \
    --name-template "$release" \
    "$BASE_PATH/code" \
    --set namespace="$namespace" \
    --set container_repository="$container_repository" \
    --set docker_version="$docker_version" \
    --set istio_ingress_gateway_ip_address="$istio_ingress_gateway_ip_address"
}

function delete_release(){
  release=$1

  helm del --purge "$release"
}
