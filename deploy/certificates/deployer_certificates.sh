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
  optionalIpAddress=$3

  cd "$BASE_PATH/deploy/certificates/$server"
  openssl genrsa -out ca.key 2048
  openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
      -subj "/C=FR/O=France/OU=smart/CN=$application"

  openssl genrsa -out tls.key 2048
  openssl req -new -out tls.csr -key tls.key \
      -subj "/C=FR/O=France/OU=smart/CN=$application"

  if [ ! -z "$optionalIpAddress" ]; then
    cert_cnf=$(cat cert.tmp | sed -e "s/APP_TO_REPLACE/$application/g" | sed -e "s/0.0.0.0/$optionalIpAddress/g")
  else
    cert_cnf=$(cat cert.tmp | sed -e "s/APP_TO_REPLACE/$application/g")
  fi
  echo "$cert_cnf" > cert.cnf

  if grep -qF "[ alt_names ]" cert.cnf;then
     # Found alternatives dns or/and ip
     openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -extensions req_ext -extfile cert.cnf \
     -out tls.crt -days 3650
  else
     openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -extfile cert.cnf -out tls.crt -days 3650
  fi

  rm -f ca.key ca.srl tls.csr

  cd "$BASE_PATH"
}