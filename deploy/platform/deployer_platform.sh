#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

. "$BASE_PATH/deploy/cluster/deployer_cluster.sh"

## FUNCTIONS
function install_python_requirements(){
    cd "$BASE_PATH/platform/controllers/"
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

function install_e2e_deps() {
    apk update
    apk add mosquitto-clients
}

function launch_python_unit_tests(){
    # Run unit tests (for python)
    cd "$BASE_PATH/platform/controllers/"
    python setup.py test
    cd ../../
}

function launch_spark_unit_tests(){
    # Run unit tests (for spark scala)
    cd "$BASE_PATH/platform/spark-jobs/"
    mvn clean test
    cd ../../
}

function launch_e2e_tests(){
    # Run e2e tests
    export ENVIRONMENT=$1
    export API_USER=$2
    export API_USER_PASS=$3
    export MQTT_USER=$4
    export MQTT_USER_PASS=$5
    
    cd "$BASE_PATH/platform/features/"
    behave
    cd ../../
}

function deploy_platform_images(){
    namespace=$1
    containerRepository=$2
    dockerVersion=$3
    s3aAccessKey=$4
    s3aSecretKey=$5
    esTruststorePass=$6
    minioTruststorePass=$7
    k8ApiserverUrl=$(get_k8_apiserver_url)
    s3PreparedDataPath="s3://bucket/prepared/"
    esNodes="https://data-indexing-elasticsearch-es-http"
    esPort=9200
    fsS3aEndpoint="data-processing-minio:9000"
    esAliasIncomingData="iot-farming"
    esAliasForHistoricalJobs="iot-farming-spark-jobs"
    esTruststoreContent=$(get_elasticsearch_truststore_content_in_base64 "$namespace" "$esTruststorePass")
    esUserPass=$(get_elastic_user_password "$namespace")

    ## Generate jars
    cd "$BASE_PATH/platform/spark-jobs/"
    mvn clean package
    cd ../../

    ## Deploy python images
    docker build -f "$BASE_PATH/deploy/platform/configuration/initialization/dockerfiles/minio/Dockerfile" \
      -t "$containerRepository/put-jars-in-minio:$dockerVersion" .
    docker push "$containerRepository/put-jars-in-minio:$dockerVersion"

    docker build -f "$BASE_PATH/deploy/platform/configuration/initialization/dockerfiles/elasticsearch/Dockerfile" \
      -t "$containerRepository/initialize-alias:$dockerVersion" .
    docker push "$containerRepository/initialize-alias:$dockerVersion"

    docker build -f "$BASE_PATH/deploy/platform/data-access/api/dockerfiles/Dockerfile" \
      -t "$containerRepository/api:$dockerVersion" .
    docker push "$containerRepository/api:$dockerVersion"

    docker build -f "$BASE_PATH/deploy/platform/data-indexing/indexer/dockerfiles/Dockerfile" \
      -t "$containerRepository/indexer:$dockerVersion" .
    docker push "$containerRepository/indexer:$dockerVersion"

    # Deploy spark images
    cp "$BASE_PATH/deploy/cluster/certificates/minio/tls.crt" "$BASE_PATH/deploy/platform/data-processing/spark-jobs/dockerfiles/"
    cd "$BASE_PATH/deploy/platform/data-processing/spark-jobs/dockerfiles/"
    docker build \
      -f Dockerfile-spark \
      --build-arg MINIO_TRUSTSTORE_PASS="$minioTruststorePass" \
      -t "$containerRepository/spark:2.4.5" .
    docker push "$containerRepository/spark:2.4.5"
    cd "$BASE_PATH/"

    cd "$BASE_PATH/deploy/platform/data-processing/spark-jobs/dockerfiles/"
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

    rm "$BASE_PATH/deploy/platform/data-processing/spark-jobs/dockerfiles/tls.crt"
}


function deploy_roles_secrets_release(){
   namespace=$1
   region=$2
   s3aAccessKey=$3
   s3aSecretKey=$4
   mqttIndexerPass=$5
   mqttDevicePass=$6
   apiUserPass=$7

   echo "Get certificates from local or secrets if exists"
   mqttCA=$(get_ssl_certificates_in_base64 "vernemq" "ca.crt")
   mqttTLS=$(get_ssl_certificates_in_base64 "vernemq" "tls.crt")
   mqttKey=$(get_ssl_certificates_in_base64 "vernemq" "tls.key")
   apiTLS=$(get_ssl_certificates_in_base64 "api" "tls.crt")
   apiKey=$(get_ssl_certificates_in_base64 "api" "tls.key")
   minioTLS=$(get_ssl_certificates_in_base64 "minio" "tls.crt")
   minioKey=$(get_ssl_certificates_in_base64 "minio" "tls.key")

   echo "Install roles and secrets"
   helm upgrade --install --debug \
     "roles-secrets" \
     "$BASE_PATH/deploy/platform/configuration/roles-secrets" \
     --namespace "$namespace" \
     --set namespace="$namespace" \
     --set mqttCA="$mqttCA" \
     --set mqttTLS="$mqttTLS" \
     --set mqttKey="$mqttKey" \
     --set minioTLS="$minioTLS" \
     --set minioKey="$minioKey" \
     --set apiTLS="$apiTLS" \
     --set apiKey="$apiKey" \
     --set s3aAccessKey="$s3aAccessKey" \
     --set s3aSecretKey="$s3aSecretKey" \
     --set mqttIndexerPassBase64="$(echo "$mqttIndexerPass" | base64)" \
     --set apiUserPassBase64="$(echo "$apiUserPass" | base64)"
}

function deploy_initialization_release(){
    namespace=$1
    containerRepository=$2
    dockerVersion=$3

    # Deploy release
    helm upgrade --install --debug \
      "configuration" \
      "$BASE_PATH/deploy/platform/configuration/initialization" \
      --namespace "$namespace" \
      --set namespace="$namespace" \
      --set containerRepository="$containerRepository" \
      --set dockerVersion="$dockerVersion" \
      --set timestamp="$(date +%s)"

    # Wait 30 seconds for deployment
    sleep 30
}

function deploy_device_management_releases(){
    namespace=$1
    region=$2
    mqttIndexerPass=$3
    mqttDevicePass=$4

    # Deploy releases
    echo "Install VerneMQ"
    helm upgrade --install --namespace "$namespace" "smart-agriculture-vernemq" vernemq/vernemq \
      -f "$BASE_PATH/deploy/platform/device-management/vernemq/values.yaml" \
      --set service.loadBalancerIP=$(get_vernemq_ip "$region") \
      --set additionalEnv[0].name=DOCKER_VERNEMQ_USER_indexer \
      --set additionalEnv[0].value="$mqttIndexerPass" \
      --set additionalEnv[1].name=DOCKER_VERNEMQ_USER_device \
      --set additionalEnv[1].value="$mqttDevicePass"
}

function deploy_data_indexing_releases(){
    namespace=$1
    containerRepository=$2
    dockerVersion=$3

    # Deploy releases
    echo "Install/Update Elasticsearch"
    kubectl apply -f https://download.elastic.co/downloads/eck/1.0.1/all-in-one.yaml
    helm upgrade --install --debug \
    "data-indexing-elasticsearch" \
    "$BASE_PATH/deploy/platform/data-indexing/elasticsearch" \
    --namespace "$namespace" \
    --set namespace="$namespace"

    helm upgrade --install --debug \
      "data-indexing-indexer" \
      "$BASE_PATH/deploy/platform/data-indexing/indexer" \
      --namespace "$namespace" \
      --set namespace="$namespace" \
      --set containerRepository="$containerRepository" \
      --set dockerVersion="$dockerVersion"
}

function deploy_data_processing_releases(){
    namespace=$1
    containerRepository=$2
    dockerVersion=$3
    s3aAccessKey=$4
    s3aSecretKey=$5
    esTruststorePass=$6
    minioTruststorePass=$7
    esTruststoreContent=$(get_elasticsearch_truststore_content_in_base64 "$namespace" "$esTruststorePass")
    esUserPass=$(get_elastic_user_password "$namespace")

    # Deploy release
    echo "Install Minio" # No need of values file for Minio here
    helm upgrade --install --namespace "$namespace" "data-processing-minio" stable/minio \
        -f "$BASE_PATH/deploy/platform/data-processing/minio/values.yaml" \
        --set accessKey="$s3aAccessKey" \
        --set secretKey="$s3aSecretKey"

    helm upgrade --install --debug \
        "data-processing-spark-jobs" \
        "$BASE_PATH/deploy/platform/spark-jobs" \
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

function deploy_data_access_releases(){
    namespace=$1
    containerRepository=$2
    dockerVersion=$3
    region=$4

    # Deploy releases
    helm upgrade --install --debug \
      "data-access-api" \
      "$BASE_PATH/deploy/platform/data-access/api" \
      --namespace "$namespace" \
      --set namespace="$namespace" \
      --set apiIp=$(get_api_ip "$region") \
      --set containerRepository="$containerRepository" \
      --set dockerVersion="$dockerVersion"
}

function delete_releases(){
  env=$1
  echo "Delete releases"
  helm del "data-processing-spark-jobs" --namespace "$env"
  helm del "data-processing-minio" --namespace "$env"
  helm del "data-access-api" --namespace "$env"
  helm del "data-indexing-indexer" --namespace "$env"
  helm del "data-indexing-elasticsearch" --namespace "$env"
  helm del "device-management-vernemq" --namespace "$env"
}

function get_elasticsearch_truststore_content_in_base64(){
  env=$1
  esTruststorePass=$2

  kubectl get secret "data-indexing-elasticsearch-es-http-certs-public" -n "$env" \
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

  echo $(kubectl get secret data-indexing-elasticsearch-es-elastic-user -n "$env" \
  -o=jsonpath='{.data.elastic}' | base64 --decode)
}