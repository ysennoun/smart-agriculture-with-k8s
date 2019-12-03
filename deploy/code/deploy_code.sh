#!/bin/bash

## PARAMETERS
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
BASE_PATH=$(realpath $SCRIPT_DIR/../)

STORAGES=("last-value" "timeseries" "historical")
MQTT_IMAGE="mqtt-client"
NOTIFICATION_IMAGE="mqtt-client"
ENVIRONMENT=${ENVIRONMENT}
VERSION=${VERSION}
CONTAINER_REPOSITORY=${CONTAINER_REPOSITORY}
PROJECT_NAME=${PROJECT_NAME}

function get_template(){
    template_file=$1
    echo $(envsubst < ${template_file})
}

function deploy_api_image(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="api-"${STORAGES[$ix]}
        docker build -f ${BASE_PATH}/deploy/code/api/docker-images/Dockerfile-${API_IMAGE} -t ${API_IMAGE}:${VERSION} .
        docker tag ${API_IMAGE}:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${API_IMAGE}:${VERSION}
        docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${API_IMAGE}:${VERSION}
    done
}

function deploy_api_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="api-"${STORAGES[$ix]}
        template=$(get_template ${BASE_PATH}/deploy/code/api/${API_IMAGE}.yaml)
        kubectl apply --template="'"${template}"'"
    done
}

function delete_api_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="api-"${STORAGES[$ix]}
        template=$(get_template ${BASE_PATH}/deploy/code/api/${API_IMAGE}.yaml)
        kubectl delete --template="'"${template}"'"
    done
}

function deploy_storage_image(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="storage-"${STORAGES[$ix]}
        docker build -f ${BASE_PATH}/deploy/code/storage/docker-images/Dockerfile-${API_IMAGE} -t ${API_IMAGE}:${VERSION} .
        docker tag ${API_IMAGE}:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${API_IMAGE}:${VERSION}
        docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${API_IMAGE}:${VERSION}
    done
}

function deploy_storage_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="storage-"${STORAGES[$ix]}
        template=$(get_template ${BASE_PATH}/deploy/code/storage/${API_IMAGE}.yaml)
        kubectl apply --template="'"${template}"'"
    done
}

function delete_storage_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="storage-"${STORAGES[$ix]}
        template=$(get_template ${BASE_PATH}/deploy/code/storage/${API_IMAGE}.yaml)
        kubectl delete --template="'"${template}"'"
    done
}

function deploy_mqtt_image(){
    docker build -f ${BASE_PATH}/deploy/code/mqtt/docker-images/Dockerfile-${MQTT_IMAGE} -t ${MQTT_IMAGE}:${VERSION} .
    docker tag ${MQTT_IMAGE}:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${MQTT_IMAGE}:${VERSION}
    docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${MQTT_IMAGE}:${VERSION}
}

function deploy_mqtt_consumer(){
    kubectl apply -f
    template=$(get_template ${BASE_PATH}/deploy/code/mqtt/${MQTT_IMAGE}.yaml)
    kubectl apply --template="'"${template}"'"
}

function delete_mqtt_consumer(){
    template=$(get_template ${BASE_PATH}/deploy/code/mqtt/${MQTT_IMAGE}.yaml)
    kubectl delete --template="'"${template}"'"
}

function deploy_notification_image(){
    docker build -f ${BASE_PATH}/deploy/code/notification/docker-images/Dockerfile-${NOTIFICATION_IMAGE} -t ${NOTIFICATION_IMAGE}:${VERSION} .
    docker tag ${NOTIFICATION_IMAGE}:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${NOTIFICATION_IMAGE}:${VERSION}
    docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${NOTIFICATION_IMAGE}:${VERSION}
}

function deploy_notification_application(){
    template=$(get_template ${BASE_PATH}/deploy/code/notification/${NOTIFICATION_IMAGE}.yaml)
    kubectl apply --template="'"${template}"'"
}

function delete_notification_application(){
    template=$(get_template ${BASE_PATH}/deploy/code/notification/${NOTIFICATION_IMAGE}.yaml)
    kubectl delete --template="'"${template}"'"
}