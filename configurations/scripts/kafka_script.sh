#!/usr/bin/env bash

## PARAMETERS
CURRENT_PATH=$(pwd)
GCP_YAML_PATH=${CURRENT_PATH}/"confluent-operator-20190726-v0.65.0/helm/providers/gcp.yaml"
CONFLUENT_OPERATOR_PATH=${CURRENT_PATH}/"confluent-operator-20190726-v0.65.0/helm/confluent-operator"

## FUNCTIONS
function install_confluent_operator(){
    helm install \
        -f ${GCP_YAML_PATH} \
        --name operator \
        --namespace operator \
        --set operator.enabled=true \
        ${CONFLUENT_OPERATOR_PATH}
    # Patch the Service Account so it can pull Confluent Platform images
    sleep 10 # wait ten seconds
    kubectl -n operator patch serviceaccount default -p '{"imagePullSecrets": [{"name": "confluent-docker-registry" }]}'
}

function install_zookeeper(){
    helm install \
        -f ${GCP_YAML_PATH} \
        --name zookeeper \
        --namespace operator \
        --set zookeeper.enabled=true \
        ${CONFLUENT_OPERATOR_PATH}
}

function install_kafka_brokers(){
    helm install \
        -f ${GCP_YAML_PATH} \
        --name kafka \
        --namespace operator \
        --set kafka.enabled=true \
        ${CONFLUENT_OPERATOR_PATH}
}

function install_schema_registry(){
    helm install \
        -f ${GCP_YAML_PATH} \
        --name schemaregistry \
        --namespace operator \
        --set schemaregistry.enabled=true \
        ${CONFLUENT_OPERATOR_PATH}
}


function install_kafka_connect(){
    helm install \
        -f ${GCP_YAML_PATH}  \
        --name connect \
        --namespace operator \
        --set connect.enabled=true \
        ${CONFLUENT_OPERATOR_PATH}
}

function install_confluent_replicator(){
    helm install \
        -f ${GCP_YAML_PATH}  \
        --name replicator \
        --namespace operator \
        --set replicator.enabled=true \
        ${CONFLUENT_OPERATOR_PATH}
}

function install_confluent_control_center(){
    helm install \
        -f ${GCP_YAML_PATH}  \
        --name controlcenter \
        --namespace operator \
        --set controlcenter.enabled=true \
        ${CONFLUENT_OPERATOR_PATH}
}

function install_confluent_ksql(){
    helm install \
        -f ${GCP_YAML_PATH}  \
        --name ksql \
        --namespace operator \
        --set ksql.enabled=true \
        ${CONFLUENT_OPERATOR_PATH}
}