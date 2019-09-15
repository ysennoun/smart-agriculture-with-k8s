#!/usr/bin/env bash

## PARAMETERS
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
BASE_PATH=$(realpath $SCRIPT_DIR/../)

RELEASE_NAME="iot-last-value"
DATABASE_USER="userlastvalue"
DATABASE_NAME="dbiotlastvalue"
DATABASE_PASSWORD="iotlastvalue1234"


## FUNCTIONS

function install_postgresql(){
    echo "Install PostgreSQL"
    helm install \
        --name ${RELEASE_NAME} \
        --set global.postgresql.postgresqlPassword=${DATABASE_PASSWORD},global.postgresql.postgresqlUsername=${DATABASE_USER},global.postgresql.postgresqlDatabase=${DATABASE_NAME} \
         stable/postgresql
}

function delete_postgresql(){
    echo "Delete PostgreSQL"
    helm del --purge ${RELEASE_NAME}
}