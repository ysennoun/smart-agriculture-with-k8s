#!/bin/bash

## PARAMETERS
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
BASE_PATH=$(realpath $SCRIPT_DIR/../)

STORAGES=("last-value" "timeseries" "historical")
MQTT_IMAGE="mqtt-client"
NOTIFICATION_IMAGE="notification"
INCOMING_DATA_PATH="s3://bucket/incoming/"
RAW_DATA_PATH="s3://bucket/raw-data/"
PREPARED_DATA_PATH="s3://bucket/prepared/"

ENVIRONMENT=${ENVIRONMENT}
VERSION=${VERSION}
CONTAINER_REPOSITORY=${CONTAINER_REPOSITORY}
PROJECT_NAME=${PROJECT_NAME}
K8S_APISERVER_HOST=${K8S_APISERVER_HOST}
K8S_APISERVER_PORT=${K8S_APISERVER_PORT}

function get_template(){
    template_file=$1
    echo $(envsubst < ${template_file})
}

function deploy_api_image(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="api-"${STORAGES[$ix]}
        docker build -f ${BASE_PATH}/deploy/code/serverless/api/docker-images/Dockerfile-${API_IMAGE} -t ${API_IMAGE}:${VERSION} .
        docker tag ${API_IMAGE}:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${API_IMAGE}:${VERSION}
        docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${API_IMAGE}:${VERSION}
    done
}

function deploy_api_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="api-"${STORAGES[$ix]}
        template=$(get_template ${BASE_PATH}/deploy/code/serverless/api/${API_IMAGE}.yaml)
        kubectl apply --template="'"${template}"'"
    done
}

function delete_api_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="api-"${STORAGES[$ix]}
        template=$(get_template ${BASE_PATH}/deploy/code/serverless/api/${API_IMAGE}.yaml)
        kubectl delete --template="'"${template}"'"
    done
}

function deploy_storage_image(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="storage-"${STORAGES[$ix]}
        docker build -f ${BASE_PATH}/deploy/code/serverless/storage/docker-images/Dockerfile-${API_IMAGE} -t ${API_IMAGE}:${VERSION} .
        docker tag ${API_IMAGE}:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${API_IMAGE}:${VERSION}
        docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${API_IMAGE}:${VERSION}
    done
}

function deploy_storage_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="storage-"${STORAGES[$ix]}
        template=$(get_template ${BASE_PATH}/deploy/code/serverless/storage/${API_IMAGE}.yaml)
        kubectl apply --template="'"${template}"'"
    done
}

function delete_storage_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="storage-"${STORAGES[$ix]}
        template=$(get_template ${BASE_PATH}/deploy/code/serverless/storage/${API_IMAGE}.yaml)
        kubectl delete --template="'"${template}"'"
    done
}

function deploy_mqtt_image(){
    docker build -f ${BASE_PATH}/deploy/code/serverless/mqtt/docker-images/Dockerfile-${MQTT_IMAGE} -t ${MQTT_IMAGE}:${VERSION} .
    docker tag ${MQTT_IMAGE}:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${MQTT_IMAGE}:${VERSION}
    docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${MQTT_IMAGE}:${VERSION}
}

function deploy_mqtt_consumer(){
    kubectl apply -f
    template=$(get_template ${BASE_PATH}/deploy/code/serverless/mqtt/${MQTT_IMAGE}.yaml)
    kubectl apply --template="'"${template}"'"
}

function delete_mqtt_consumer(){
    template=$(get_template ${BASE_PATH}/deploy/code/serverless/mqtt/${MQTT_IMAGE}.yaml)
    kubectl delete --template="'"${template}"'"
}

function deploy_notification_image(){
    docker build -f ${BASE_PATH}/deploy/code/serverless/notification/docker-images/Dockerfile-${NOTIFICATION_IMAGE} -t ${NOTIFICATION_IMAGE}:${VERSION} .
    docker tag ${NOTIFICATION_IMAGE}:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${NOTIFICATION_IMAGE}:${VERSION}
    docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${NOTIFICATION_IMAGE}:${VERSION}
}

function deploy_notification_application(){
    template=$(get_template ${BASE_PATH}/deploy/code/serverless/notification/${NOTIFICATION_IMAGE}.yaml)
    kubectl apply --template="'"${template}"'"
}

function delete_notification_application(){
    template=$(get_template ${BASE_PATH}/deploy/code/serverless/notification/${NOTIFICATION_IMAGE}.yaml)
    kubectl delete --template="'"${template}"'"
}

function deploy_historical_job_json_to_parquet_image(){
    wget https://apache.mirrors.benatherton.com/spark/spark-2.4.4/spark-2.4.4.tgz
    tar -zxvf spark-2.4.4.tgz
    ./bin/docker-image-tool.sh -r ${CONTAINER_REPOSITORY} -t ${ENVIRONMENT}-spark-on-docker:2.4.4 build
    ./bin/docker-image-tool.sh -r ${CONTAINER_REPOSITORY} -t ${ENVIRONMENT}-spark-on-docker:2.4.4 push
    rm -f spark-2.4.4.tgz
    rm -rf spark-2.4.4/
    docker build -f ${BASE_PATH}/deploy/code/historical-jobs/docker-images/Dockerfile-json-to-parquet -t ${ENVIRONMENT}-spark-json-to-parquet:${VERSION} .
    docker tag ${ENVIRONMENT}-spark-json-to-parquet:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${ENVIRONMENT}-spark-json-to-parquet:${VERSION}
    docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${ENVIRONMENT}-spark-json-to-parquet:${VERSION}
}

function deploy_historical_job_json_to_parquet_application(){
    template=$(get_template ${BASE_PATH}/deploy/code/historical-jobs/${ENVIRONMENT}-spark-json-to-parquet.yaml)
    kubectl apply --template="'"${template}"'"
}

function delete_historical_job_json_to_parquet_application(){
    template=$(get_template ${BASE_PATH}/deploy/code/historical-jobs/${ENVIRONMENT}-spark-json-to-parquet.yaml)
    kubectl delete --template="'"${template}"'"
}