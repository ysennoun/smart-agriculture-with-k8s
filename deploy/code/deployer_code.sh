#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

ES_ALIAS_INCOMING_DATA="smart-agriculture"
ES_ALIAS_FOR_HISTORICAL_JOBS="historical-jobs"
ES_ALIAS_FOR_AVERAGE_PER_DEVICE_AND_DATE="average-per-device-and-date"
S3_PREPARED_DATA_PATH="s3://bucket/prepared/"


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
    curl https://sdk.cloud.google.com | bash -s -- --disable-prompts
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
    containerRepository=$1
    dockerVersion=$2

    docker build -f "$BASE_PATH/deploy/code/dockerfiles/serverless/api/Dockerfile-api" \
      -t "$containerRepository/api:$dockerVersion" .
    docker push "$containerRepository/api:$dockerVersion"

    docker build -f "$BASE_PATH/deploy/code/dockerfiles/serverless/indexer/Dockerfile-indexer" \
      -t "$containerRepository/indexer:$dockerVersion" .
    docker push "$containerRepository/indexer:$dockerVersion"

    docker build -f "$BASE_PATH/deploy/code/dockerfiles/serverless/device/Dockerfile-mqtt-client" \
      -t "$containerRepository/mqtt-client:$dockerVersion" .
    docker push "$containerRepository/mqtt-client:$dockerVersion"

    docker build -f "$BASE_PATH/deploy/code/dockerfiles/serverless/notification/Dockerfile-notification" \
      -t "$containerRepository/notification:$dockerVersion" .
    docker push "$containerRepository/notification:$dockerVersion"
}

function deploy_spark_within_docker_image(){
    containerRepository=$1
    wget https://apache.mirrors.benatherton.com/spark/spark-2.4.4/spark-2.4.4.tgz
    tar -zxvf spark-2.4.4.tgz
    cd spark-2.4.4/
    ./build/mvn -pl :spark-assembly_2.11 clean install
    ./bin/docker-image-tool.sh -r "$containerRepository" -t "2.4.4" build
    ./bin/docker-image-tool.sh -r "$containerRepository" -t "2.4.4" push
    cd ..
    rm -f spark-2.4.4.tgz
    rm -rf spark-2.4.4/
}

function deploy_historical_jobs_docker_images(){
    containerRepository=$1
    dockerVersion=$2
    k8ApiserverUrl=$3
    esNodes=$4
    esPort=$5
    fsS3aEndpoint=$6
    esAliasIncomingData=$ES_ALIAS_INCOMING_DATA
    esAliasForHistoricalJobs=$ES_ALIAS_FOR_HISTORICAL_JOBS
    esAliasForAveragePerDeviceAndDate=$ES_ALIAS_FOR_AVERAGE_PER_DEVICE_AND_DATE
    s3_prepared_data_path=$S3_PREPARED_DATA_PATH

    cd "$BASE_PATH/code/historical-jobs/"
    mvn clean package
    cd ../../

    docker build \
      --build-arg CONTAINER_REPOSITORY="$containerRepository" \
      --build-arg K8S_APISERVER_URL="$k8ApiserverUrl" \
      --build-arg ES_NODES="$esNodes" \
      --build-arg ES_PORT="$esPort" \
      --build-arg FS_S3A_ENDPOINT="$fsS3aEndpoint" \
      --build-arg ES_ALIAS_INCOMING_DATA="$esAliasIncomingData" \
      --build-arg ES_ALIAS_FOR_HISTORICAL_JOBS="$esAliasForHistoricalJobs" \
      --build-arg ES_ALIAS_FOR_AVERAGE_PER_DEVICE_AND_DATE="$esAliasForAveragePerDeviceAndDate" \
      --build-arg S3_PREPARED_DATA_PATH="$s3_prepared_data_path" \
      -f "$BASE_PATH/deploy/code/dockerfiles/historical-jobs/Dockerfile-es-to-parquet" \
      -t "$containerRepository/spark-es-to-parquet:$dockerVersion" .
    docker push "$containerRepository/spark-es-to-parquet:$dockerVersion"

    docker build \
      --build-arg CONTAINER_REPOSITORY="$containerRepository" \
      --build-arg K8S_APISERVER_URL="$k8ApiserverUrl" \
      --build-arg ES_NODES="$esNodes" \
      --build-arg ES_PORT="$esPort" \
      --build-arg FS_S3A_ENDPOINT="$fsS3aEndpoint" \
      --build-arg ES_ALIAS_INCOMING_DATA="$esAliasIncomingData" \
      --build-arg ES_ALIAS_FOR_HISTORICAL_JOBS="$esAliasForHistoricalJobs" \
      --build-arg ES_ALIAS_FOR_AVERAGE_PER_DEVICE_AND_DATE="$esAliasForAveragePerDeviceAndDate" \
      --build-arg S3_PREPARED_DATA_PATH="$s3_prepared_data_path" \
      -f "$BASE_PATH/deploy/code/dockerfiles/historical-jobs/Dockerfile-average-point-per-device-and-date" \
      -t "$containerRepository/spark-average-point-per-device-and-date:$dockerVersion" .
    docker push "$containerRepository/spark-average-point-per-device-and-date:$dockerVersion"
}

function deploy_release_from_templates(){
  release=$1
  namespace=$2
  infrastructureRelease=$3
  containerRepository=$4
  dockerVersion=$5
  istioIngressGatewayIpAddress=$6

  helm install --debug \
    --name-template "$release" \
    "$BASE_PATH/deploy/code" \
    --set infrastructureRelease="$infrastructureRelease" \
    --set namespace="$namespace" \
    --set containerRepository="$containerRepository" \
    --set dockerVersion="$dockerVersion" \
    --set istioIngressGatewayIpAddress="$istioIngressGatewayIpAddress"
}

function delete_release(){
  release=$1
  env=$2
  helm del "$release" --namespace "$env"
}
