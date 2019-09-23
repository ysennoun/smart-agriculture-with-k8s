#!/bin/bash

## PARAMETERS
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
BASE_PATH=$(realpath $SCRIPT_DIR/../)

STORAGES=("last-value" "timeseries" "historical")
CONNECTOR_IMAGE="iot-mqtt-client"
NOTIFICATION_IMAGE="iot-mqtt-client"
CONNECTOR_IMAGE="iot-mqtt-client"
VERSION="latest"
REPOSITORY=${REPOSITORY}
PROJECT_NAME=${PROJECT_NAME}

function deploy_api_image(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="iot-api-"${STORAGES[$ix]}
        docker build -f ${BASE_PATH}/deploy/configuration/api/docker-images/Dockerfile-${API_IMAGE} -t ${API_IMAGE}:${VERSION} .
        docker tag ${API_IMAGE}:${VERSION} ${REPOSITORY}/${PROJECT_NAME}/${API_IMAGE}:${VERSION}
        docker push ${REPOSITORY}/${PROJECT_NAME}/${API_IMAGE}:${VERSION}
    done
}

function deploy_api_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="iot-api-"${STORAGES[$ix]}
        kubectl apply -f ${BASE_PATH}/deploy/configuration/api/${API_IMAGE}.yaml
    done
}

function delete_api_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="iot-api-"${STORAGES[$ix]}
        kubectl delete -f ${BASE_PATH}/deploy/configuration/api/${API_IMAGE}.yaml
    done
}

function deploy_storage_image(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="iot-storage-"${STORAGES[$ix]}
        docker build -f ${BASE_PATH}/deploy/configuration/storage/docker-images/Dockerfile-${API_IMAGE} -t ${API_IMAGE}:${VERSION} .
        docker tag ${API_IMAGE}:${VERSION} ${REPOSITORY}/${PROJECT_NAME}/${API_IMAGE}:${VERSION}
        docker push ${REPOSITORY}/${PROJECT_NAME}/${API_IMAGE}:${VERSION}
    done
}

function deploy_storage_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="iot-storage-"${STORAGES[$ix]}
        kubectl apply -f ${BASE_PATH}/deploy/configuration/storage/${API_IMAGE}.yaml
    done
}

function delete_storage_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="iot-storage-"${STORAGES[$ix]}
        kubectl delete -f ${BASE_PATH}/deploy/configuration/storage/${API_IMAGE}.yaml
    done
}

function deploy_connector_image(){
    docker build -f ${BASE_PATH}/deploy/configuration/connector/docker-images/Dockerfile-${CONNECTOR_IMAGE} -t ${CONNECTOR_IMAGE}:${VERSION} .
    docker tag ${CONNECTOR_IMAGE}:${VERSION} ${REPOSITORY}/${PROJECT_NAME}/${CONNECTOR_IMAGE}:${VERSION}
    docker push ${REPOSITORY}/${PROJECT_NAME}/${CONNECTOR_IMAGE}:${VERSION}
}

function deploy_connector_application(){
    kubectl apply -f ${BASE_PATH}/deploy/configuration/connector/${CONNECTOR_IMAGE}.yaml
}

function delete_connector_application(){
    kubectl delete -f ${BASE_PATH}/deploy/configuration/connector/${CONNECTOR_IMAGE}.yaml
}

function deploy_notification_image(){
    docker build -f ${BASE_PATH}/deploy/configuration/notification/docker-images/Dockerfile-${NOTIFICATION_IMAGE} -t ${NOTIFICATION_IMAGE}:${VERSION} .
    docker tag ${NOTIFICATION_IMAGE}:${VERSION} ${REPOSITORY}/${PROJECT_NAME}/${NOTIFICATION_IMAGE}:${VERSION}
    docker push ${REPOSITORY}/${PROJECT_NAME}/${NOTIFICATION_IMAGE}:${VERSION}
}

function deploy_notification_application(){
    kubectl apply -f ${BASE_PATH}/deploy/configuration/notification/${NOTIFICATION_IMAGE}.yaml
}

function delete_notification_application(){
    kubectl delete -f ${BASE_PATH}/deploy/configuration/notification/${NOTIFICATION_IMAGE}.yaml
}