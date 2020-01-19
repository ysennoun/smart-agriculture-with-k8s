#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

INCOMING_DATA_PATH="s3://bucket/incoming/"
RAW_DATA_PATH="s3://bucket/raw-data/"
PREPARED_DATA_PATH="s3://bucket/prepared/"

ENVIRONMENT="$ENVIRONMENT"
VERSION="$VERSION"
CONTAINER_REPOSITORY="$CONTAINER_REPOSITORY"
PROJECT_NAME="$PROJECT_NAME"
K8S_APISERVER_HOST="$K8S_APISERVER_HOST"
K8S_APISERVER_PORT="$K8S_APISERVER_PORT"

function get_yaml_file(){
    template_file=$1
    yaml_file="${template_file%.template}.template"
    envsubst < "$template_file" > "$yaml_file"
    echo "$yaml_file"
}

function install_python_requirements(){
    cd "$BASE_PATH/code/serverless/"
    pip install -r requirements.txt
    pip install -r test_requirements.txt
    cd ../../
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

function deploy_api_image(){
    docker build -f "$BASE_PATH/deploy/code/serverless/api/docker-images/Dockerfile-api" -t "$CONTAINER_REPOSITORY/api:$VERSION" .
    docker push "$CONTAINER_REPOSITORY/api:$VERSION"
}

function deploy_api_application(){
    yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/serverless/api/api.template")
    kubectl apply --filename="$yaml_file"
}

function delete_api_application(){
    yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/serverless/api/api.template")
    kubectl delete --filename="$yaml_file"
}

function deploy_indexer_image(){
    docker build -f "$BASE_PATH/deploy/code/serverless/storage/docker-images/Dockerfile-indexer" -t "$CONTAINER_REPOSITORY/indexer:$VERSION" .
    docker push "$CONTAINER_REPOSITORY/indexer:$VERSION"
}

function deploy_indexer_application(){
    yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/serverless/storage/indexer.template")
    kubectl apply --filename="$yaml_file"
}

function delete_storage_application(){
    template=$(get_yaml_file "$BASE_PATH/deploy/code/serverless/storage/indexer.template")
    kubectl delete --filename="$template"
}

function deploy_mqtt_image(){
    docker build -f "$BASE_PATH/deploy/code/serverless/mqtt/docker-images/Dockerfile-mqtt-client" -t "$CONTAINER_REPOSITORY/mqtt-client:$VERSION" .
    docker push "$CONTAINER_REPOSITORY/mqtt-client:$VERSION"
}

function deploy_mqtt_client(){
    yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/serverless/mqtt/mqtt-client.template")
    kubectl apply --filename="$template"
}

function delete_mqtt_client(){
    yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/serverless/mqtt/mqtt-client.template")
    kubectl delete --filename="$yaml_file"
}

function deploy_notification_image(){
    docker build -f "$BASE_PATH/deploy/code/serverless/notification/docker-images/Dockerfile-notification" -t "$CONTAINER_REPOSITORY/notification:$VERSION" .
    docker push "$CONTAINER_REPOSITORY/notification:$VERSION"
}

function deploy_notification_application(){
    yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/serverless/notification/notification.template")
    kubectl apply --filename="$template"
}

function delete_notification_application(){
    yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/serverless/notification/notification.template")
    kubectl delete --filename="$template"
}

function deploy_spark_on_docker_image(){
    wget https://apache.mirrors.benatherton.com/spark/spark-2.4.4/spark-2.4.4.tgz
    tar -zxvf spark-2.4.4.tgz
    cd spark-2.4.4/
    ./bin/docker-image-tool.sh -r "$CONTAINER_REPOSITORY" -t "spark-on-docker:2.4.4" build
    ./ls a-lbin/docker-image-tool.sh -r "$CONTAINER_REPOSITORY" -t "spark-on-docker:2.4.4" push
    cd ..
    rm -f spark-2.4.4.tgz
    rm -rf spark-2.4.4/
}

function deploy_historical_job_es_to_parquet_image(){
    docker build -f "$BASE_PATH/deploy/code/historical-jobs/docker-images/Dockerfile-es-to-parquet" -t "$CONTAINER_REPOSITORY/spark-es-to-parquet:$VERSION" .
    docker push "$CONTAINER_REPOSITORY/spark-es-to-parquet:$VERSION"
}

function deploy_historical_job_es_to_parquet_application(){
    yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/historical-jobs/es-to-parquet.template")
    kubectl apply --filename="$template"
}

function delete_historical_job_es_to_parquet_application(){
    yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/historical-jobs/es-to-parquet.template")
    kubectl delete --filename="$template"
}

function deploy_historical_job_average_point_per_device_and_date_image(){
    docker build -f "$BASE_PATH/deploy/code/historical-jobs/docker-images/Dockerfile-average-point-per-device-and-date" -t "$CONTAINER_REPOSITORY/spark-average-point-per-device-and-date:$VERSION" .
    docker push "$CONTAINER_REPOSITORY/spark-average-point-per-device-and-date:$VERSION"
}

function deploy_historical_job_average_point_per_device_and_date_application(){
    yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/historical-jobs/average-point-per-device-and-date.template")
    kubectl apply --filename="$template"
}

function delete_historical_job_average_point_per_device_and_date_application(){
    yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/historical-jobs/average-point-per-device-and-date.template")
    kubectl delete --filename="$template"
}

function deploy_ingress_for_kn_function_api(){
  yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/ingress/ingress-for-kn-function-api.template")
  kubectl apply --filename="$template"
}

function delete_ingress_for_kn_function_api(){
  yaml_file=$(get_yaml_file "$BASE_PATH/deploy/code/ingress/ingress-for-kn-function-api.template")
  kubectl delete --filename="$template"
}