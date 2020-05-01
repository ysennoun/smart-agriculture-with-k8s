#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

. "$BASE_PATH/deploy/cluster/deployer_cluster.sh"

## FUNCTIONS
function install_python_requirements(){
    cd "$BASE_PATH/platform/serverless/"
    pip install -r requirements.txt
    pip install -r setup_requirements.txt
    pip install -r test_requirements.txt
    cd ../../
}

function install_deps() {
    apk update
    apk fetch openjdk8
    apk add openjdk8
    apk add maven
    apk add jq
}

function launch_python_unit_tests(){
    # Run unit tests (for python)
    cd "$BASE_PATH/platform/serverless/"
    python setup.py test
    cd ../../
}

function launch_spark_unit_tests(){
    # Run unit tests (for spark scala)
    cd "$BASE_PATH/platform/historical-jobs/"
    mvn clean test
    cd ../../
}

function launch_e2e_tests(){
    # Run e2e tests
    export ENVIRONMENT=$1
    containerRepository=$2
    dockerVersion=$3
    export BACK_END_USER=$4
    export BACK_END_USER_PASS=$5
    export MQTT_USER=$6
    export MQTT_USER_PASS=$7
    export DOCKER_IMAGE="$containerRepository/features:$dockerVersion"

    ## Deplopy docker image
    docker build -f "$BASE_PATH/deploy/platform/features/dockerfiles/Dockerfile-features" \
      -t "$containerRepository/features:$dockerVersion" .
    docker push "$containerRepository/features:$dockerVersion"

    cd "$BASE_PATH/platform/features/"
    behave
    cd ../../
}

function deploy_jars_alias_deployment_image_and_release(){
    namespace=$1
    containerRepository=$2
    dockerVersion=$3

    ## Generate jars
    cd "$BASE_PATH/platform/historical-jobs/"
    mvn clean package
    cd ../../

    ## Deplopy docker image
    docker build -f "$BASE_PATH/deploy/platform/serverless/deployment/dockerfiles/minio/Dockerfile-put-jars-in-minio" \
      -t "$containerRepository/put-jars-in-minio:$dockerVersion" .
    docker push "$containerRepository/put-jars-in-minio:$dockerVersion"

    docker build -f "$BASE_PATH/deploy/platform/serverless/deployment/dockerfiles/elasticsearch/Dockerfile-initialize-alias" \
      -t "$containerRepository/initialize-alias:$dockerVersion" .
    docker push "$containerRepository/initialize-alias:$dockerVersion"

    # Deploy release
    helm upgrade --install --debug \
      "smart-agriculture-jars-alias-deployment" \
      "$BASE_PATH/deploy/platform/serverless/deployment" \
      --namespace "$namespace" \
      --set namespace="$namespace" \
      --set containerRepository="$containerRepository" \
      --set dockerVersion="$dockerVersion" \
      --set timestamp="$(date +%s)"

    # Wait 30 seconds for deployment
    sleep 30
}

function deploy_application_images_and_release(){
    namespace=$1
    region=$2
    containerRepository=$3
    dockerVersion=$4

    # Deploy docker images
    docker build -f "$BASE_PATH/deploy/platform/serverless/application/dockerfiles/back_end/Dockerfile-back-end" \
      -t "$containerRepository/back-end:$dockerVersion" .
    docker push "$containerRepository/back-end:$dockerVersion"

    docker build -f "$BASE_PATH/deploy/platform/serverless/application/dockerfiles/indexer/Dockerfile-indexer" \
      -t "$containerRepository/indexer:$dockerVersion" .
    docker push "$containerRepository/indexer:$dockerVersion"

    # Deploy release
    helm upgrade --install --debug \
      "smart-agriculture-serverless" \
      "$BASE_PATH/deploy/platform/serverless/application" \
      --namespace "$namespace" \
      --set namespace="$namespace" \
      --set backEndIp=$(get_back_end_ip "$region") \
      --set containerRepository="$containerRepository" \
      --set dockerVersion="$dockerVersion"
}

function deploy_historical_jobs_docker_images_and_release(){
    namespace=$1
    containerRepository=$2
    dockerVersion=$3
    s3aAccessKey=$4
    s3aSecretKey=$5
    esTruststorePass=$6
    minioTruststorePass=$7
    k8ApiserverUrl=$(get_k8_apiserver_url)
    s3PreparedDataPath="s3://bucket/prepared/"
    esNodes="https://smart-agriculture-elasticsearch-es-http"
    esPort=9200
    fsS3aEndpoint="smart-agriculture-minio:9000"
    esAliasIncomingData="iot-farming"
    esAliasForHistoricalJobs="iot-farming-historical-jobs"
    esTruststoreContent=$(get_elasticsearch_truststore_content_in_base64 "$namespace" "$esTruststorePass")
    esUserPass=$(get_elastic_user_password "$namespace")

    # Deploy docker images
    cp "$BASE_PATH/deploy/cluster/certificates/minio/tls.crt" "$BASE_PATH/deploy/platform/historical-jobs/dockerfiles/"
    cd "$BASE_PATH/deploy/platform/historical-jobs/dockerfiles/"
    docker build \
      -f Dockerfile-spark \
      --build-arg MINIO_TRUSTSTORE_PASS="$minioTruststorePass" \
      -t "$containerRepository/spark:2.4.5" .
    docker push "$containerRepository/spark:2.4.5"
    cd "$BASE_PATH/"

    cd "$BASE_PATH/deploy/platform/historical-jobs/dockerfiles/"
    docker build \
      --build-arg CONTAINER_REPOSITORY="$containerRepository" \
      --build-arg DOCKER_VERSION="$dockerVersion" \
      --build-arg K8S_APISERVER_URL="$k8ApiserverUrl" \
      --build-arg ES_NODES="$esNodes" \
      --build-arg ES_PORT="$esPort" \
      --build-arg FS_S3A_ENDPOINT="$fsS3aEndpoint" \
      --build-arg ES_ALIAS_INCOMING_DATA="$esAliasIncomingData" \
      --build-arg ES_ALIAS_FOR_HISTORICAL_JOBS="$esAliasForHistoricalJobs" \
      --build-arg S3_PREPARED_DATA_PATH="$s3PreparedDataPath" \
      --build-arg MINIO_TRUSTSTORE_PASS="$minioTruststorePass" \
      --build-arg ENVIRONMENT="$namespace" \
      -f "Dockerfile-es-to-parquet" \
      -t "$containerRepository/spark-es-to-parquet:$dockerVersion" .
    docker push "$containerRepository/spark-es-to-parquet:$dockerVersion"
    cd "$BASE_PATH/"

    rm "$BASE_PATH/deploy/platform/historical-jobs/dockerfiles/tls.crt"

    # Deploy release
    helm upgrade --install --debug \
    "smart-agriculture-historical-jobs" \
    "$BASE_PATH/deploy/platform/historical-jobs" \
    --namespace "$namespace" \
    --set namespace="$namespace" \
    --set containerRepository="$containerRepository" \
    --set dockerVersion="$dockerVersion" \
    --set esTruststoreContent="$esTruststoreContent" \
    --set s3aAccessKey="$s3aAccessKey" \
    --set s3aSecretKey="$s3aSecretKey" \
    --set esUserPass="$esUserPass" \
    --set esTruststorePass="$esTruststorePass" \
    --set minioTruststorePass="$minioTruststorePass"
}

function delete_modules_code(){
  env=$1
  echo "Delete Modules code"
  helm del "smart-agriculture-serverless" --namespace "$env"
  helm del "smart-agriculture-historical-jobs" --namespace "$env"
}

function get_elasticsearch_truststore_content_in_base64(){
  env=$1
  esTruststorePass=$2

  kubectl get secret "smart-agriculture-elasticsearch-es-http-certs-public" -n "$env" \
    -o go-template='{{index .data "tls.crt" | base64decode }}' > tls.crt
  keytool -import \
    -alias tls \
    -file tls.crt \
    -keystore truststore.jks \
    -storepass "$esTruststorePass" \
    -noprompt

  truststore_content=$(cat truststore.jks | base64 | tr -d '\n')
  rm tls.crt
  rm truststore.jks
  echo "$truststore_content"
}


function get_elastic_user_password(){
  env=$1

  echo $(kubectl get secret smart-agriculture-elasticsearch-es-elastic-user -n "$env" \
  -o=jsonpath='{.data.elastic}' | base64 --decode)
}