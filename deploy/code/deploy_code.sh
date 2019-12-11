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

function get_yaml_file(){
    template_file=$1
    yaml_file=${template_file%.template}.template
    envsubst < ${template_file} > ${yaml_file}
    echo ${yaml_file}
}

function install_python_requirements(){
    cd ${BASE_PATH}/code/serverless/
    pip install -r requirements.txt
    pip install -r test_requirements.txt
    cd ../../

    cd ${BASE_PATH}/code/redis-to-minio/
    pip install -r requirements.txt
    pip install -r test_requirements.txt
    cd ../../
}

function launch_python_unit_tests(){
    # Run unit tests (for python)
    cd ${BASE_PATH}/code/serverless/
    python setup.py test
    cd ../../

    cd ${BASE_PATH}/code/redis-to-minio/
    python setup.py test
    cd ../../
}

function launch_spark_unit_tests(){
    # Run unit tests (for spark scala)
    cd ${BASE_PATH}/code/historical-jobs/
    mvn clean test
    cd ../../
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
        yaml_file=$(get.template_file ${BASE_PATH}/deploy/code/serverless/api/${API_IMAGE}.template)
        kubectl apply --filename="'"${yaml_file}"'"
    done
}

function delete_api_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="api-"${STORAGES[$ix]}
        yaml_file=$(get_template ${BASE_PATH}/deploy/code/serverless/api/${API_IMAGE}.template)
        kubectl delete --filename="'"${yaml_file}"'"
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
        yaml_file=$(get_yaml_file ${BASE_PATH}/deploy/code/serverless/storage/${API_IMAGE}.template)
        kubectl apply --filename="'"${yaml_file}"'"
    done
}

function delete_storage_application(){
    for ix in ${!STORAGES[*]}
    do
        API_IMAGE="storage-"${STORAGES[$ix]}
        template=$(get_template ${BASE_PATH}/deploy/code/serverless/storage/${API_IMAGE}.template)
        kubectl delete --filename=${template}
    done
}

function deploy_mqtt_image(){
    docker build -f ${BASE_PATH}/deploy/code/serverless/mqtt/docker-images/Dockerfile-${MQTT_IMAGE} -t ${MQTT_IMAGE}:${VERSION} .
    docker tag ${MQTT_IMAGE}:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${MQTT_IMAGE}:${VERSION}
    docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${MQTT_IMAGE}:${VERSION}
}

function deploy_mqtt_consumer(){
    kubectl apply -f
    yaml_file=$(get_yaml_file ${BASE_PATH}/deploy/code/serverless/mqtt/${MQTT_IMAGE}.template)
    kubectl apply --filename=${template}
}

function delete_mqtt_consumer(){
    yaml_file=$(get_yaml_file ${BASE_PATH}/deploy/code/serverless/mqtt/${MQTT_IMAGE}.template)
    kubectl delete --filename=${yaml_file}
}

function deploy_notification_image(){
    docker build -f ${BASE_PATH}/deploy/code/serverless/notification/docker-images/Dockerfile-${NOTIFICATION_IMAGE} -t ${NOTIFICATION_IMAGE}:${VERSION} .
    docker tag ${NOTIFICATION_IMAGE}:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${NOTIFICATION_IMAGE}:${VERSION}
    docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${NOTIFICATION_IMAGE}:${VERSION}
}

function deploy_notification_application(){
    yaml_file=$(get_yaml_file ${BASE_PATH}/deploy/code/serverless/notification/${NOTIFICATION_IMAGE}.template)
    kubectl apply --filename=${template}
}

function delete_notification_application(){
    yaml_file=$(get_yaml_file ${BASE_PATH}/deploy/code/serverless/notification/${NOTIFICATION_IMAGE}.template)
    kubectl delete --filename=${template}
}

function deploy_spark_on_docker_image(){
    wget https://apache.mirrors.benatherton.com/spark/spark-2.4.4/spark-2.4.4.tgz
    tar -zxvf spark-2.4.4.tgz
    ./bin/docker-image-tool.sh -r ${CONTAINER_REPOSITORY} -t ${ENVIRONMENT}-spark-on-docker:2.4.4 build
    ./bin/docker-image-tool.sh -r ${CONTAINER_REPOSITORY} -t ${ENVIRONMENT}-spark-on-docker:2.4.4 push
    rm -f spark-2.4.4.tgz
    rm -rf spark-2.4.4/
}

function deploy_historical_job_json_to_parquet_image(){
    docker build -f ${BASE_PATH}/deploy/code/historical-jobs/docker-images/Dockerfile-json-to-parquet -t ${ENVIRONMENT}-spark-json-to-parquet:${VERSION} .
    docker tag ${ENVIRONMENT}-spark-json-to-parquet:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${ENVIRONMENT}-spark-json-to-parquet:${VERSION}
    docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${ENVIRONMENT}-spark-json-to-parquet:${VERSION}
}

function deploy_historical_job_json_to_parquet_application(){
    yaml_file=$(get_yaml_file ${BASE_PATH}/deploy/code/historical-jobs/${ENVIRONMENT}-spark-json-to-parquet.template)
    kubectl apply --filename=${template}
}

function delete_historical_job_json_to_parquet_application(){
    yaml_file=$(get_yaml_file ${BASE_PATH}/deploy/code/historical-jobs/${ENVIRONMENT}-spark-json-to-parquet.template)
    kubectl delete --filename=${template}
}

function deploy_historical_limited_number_of_data_selected_image(){
    docker build -f ${BASE_PATH}/deploy/code/historical-jobs/docker-images/Dockerfile-limited-number-of-data-selected -t ${ENVIRONMENT}-spark-imited-number-of-data-selected:${VERSION} .
    docker tag ${ENVIRONMENT}-spark-imited-number-of-data-selected:${VERSION} ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${ENVIRONMENT}-spark-imited-number-of-data-selected:${VERSION}
    docker push ${CONTAINER_REPOSITORY}/${PROJECT_NAME}/${ENVIRONMENT}-spark-imited-number-of-data-selected:${VERSION}
}