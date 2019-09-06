# smart-agriculture-with-k8s

Build a smart agriculture project with Kubernetes

## How to begin ?

First you have to:

- Create a [GCP account](https://console.cloud.google.com/)
- Create a gcp project by given a project-id (example: my-iot-project)
- Install [Google Cloud SDK](https://cloud.google.com/sdk/docs/downloads-interactive)
- Install [Helm](https://helm.sh/docs/using_helm/#installing-helm), the package manager for Kubernetes
- Install [Docker](https://docs.docker.com/install/)

## Configuration for Kubernetes cluster

### Configure gcloud

Modify the following parameters before those commands:

    export PROJECT_ID="your-project-id"
    export COMPUTE_ZONE="your-selected-zone"
    export COMPUTE_REGION="your-selected-region"
    gcloud config set project ${PROJECT_ID}
    gcloud config set compute/zone ${COMPUTE_ZONE}
    gcloud config set compute/region ${COMPUTE_REGION}
    gcloud components update

### Configuration for Kafka deployment on Kubernetes

Download following project from Kafka Confluent:

    wget https://platform-ops-bin.s3-us-west-1.amazonaws.com/operator/confluent-operator-20190726-v0.65.0.tar.gz
    tar -xvzf confluent-operator-20190726-v0.65.0.tar.gz
    rm -f confluent-operator-20190726-v0.65.0.tar.gz

Make the following configuration changes:
- Go to the helm/providers
- Open the gcp.yaml file
- Validate or change your region and zone or zones (if your cluster spans multiple availability zones)
- Validate or change your storage provisioner. See Storage Classe Provisioners for configuration examples. The example below uses GCE persistent disk storage (gce-pd) and solid-state drives (pd-ssd).
- Change the domain name for 'loadBalancer'
- The deployment steps use SASL/PLAIN security with TLS disabled. See [Configuring security](https://docs.confluent.io/current/installation/operator/co-security.html#co-security)  to set up the component YAML files with TLS enabled


### Install IoT Platform

Run the following script to install this IoT platform on your GCP Account:

    ./infrastructure/iot_platform.sh install
    

### Delete IoT Platform

Run the following script to delete the IoT platform on your GCP Account:

    ./infrastructure/iot_platform.sh delete
    
    
    
### Container Registry

    gcloud auth configure-docker
    docker build -f <dockerfile> -t <image:version> .
    docker tag <image:version> eu.gcr.io/ysennoun-iot/<image:version>
    docker tag iot-kn-function eu.gcr.io/ysennoun-iot/iot-kn-function

