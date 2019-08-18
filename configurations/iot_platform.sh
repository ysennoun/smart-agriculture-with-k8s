#!/usr/bin/env bash

# PARAMETERS
CURRENT_PATH=$(pwd)

# IMPORTS
source ${CURRENT_PATH}/configurations/scripts/kubernetes_script.sh
source ${CURRENT_PATH}/configurations/scripts/kafka_script.sh


######## FUNCTIONS ########

function install_iot_platform(){
    # Activate billing and enable APIs
    activate_billing ${PROJECT_ID}
    enable_apis

    # Create Kubernetes Cluster
    create_k8s_cluster

    # Deploy Knative
    deploy_knative
    visualize_knative_deployment

    # Deploy Confluent Operator, Zookeeper and Kafka brokers
    install_confluent_operator
    install_zookeeper
    install_kafka_brokers
}

function delete_iot_platform(){
    # Delete Kubernetes Cluster
    delete_k8s_cluster
}


######## MAIN ########

if [[ "$#" -ne 1 ]]; then
    echo "Illegal number of parameters. Run by using parameter 'install' or 'delete'"
    exit 0
fi

VAR1=$1

if [[ "${VAR1}" == "install" ]]
then
    install_iot_platform
elif [[ "${VAR1}" == "delete" ]]
then
    delete_iot_platform
else
    echo "Illegal parameter. Run by using parameter 'install' or 'delete'"
fi