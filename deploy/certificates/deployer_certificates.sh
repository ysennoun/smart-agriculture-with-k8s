#!/bin/bash

set -e

## PARAMETERS
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
BASE_PATH=$(realpath "$SCRIPT_DIR/../")

## FUNCTIONS
function create_ssl_certificates(){
  server=$1
  application=$2

  cd "$BASE_PATH/deploy/certificates/$server"
  openssl genrsa -out ca.key 2048
  openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
      -subj "/C=FR/O=France/OU=smart/CN=$application"

  openssl genrsa -out tls.key 2048
  openssl req -new -out tls.csr -key tls.key \
      -subj "/C=FR/O=France/OU=smart/CN=$application"

  cert_cnf=$(cat cert.tmp | sed -e "s/APP_TO_REPLACE/$application/g")
  echo "$cert_cnf" > cert.cnf
  openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -extfile cert.cnf -out tls.crt -days 3650
  cd "$BASE_PATH"
}