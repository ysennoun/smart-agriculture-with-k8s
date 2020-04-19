# Project `smart-agriculture-with-k8s`

Build a smart agriculture project with Kubernetes and Knative

## How to begin ?

### Creat a Gmail 
activate Gmail API for python

https://developers.google.com/gmail/api/quickstart/python

### GCP Account
Create a [GCP account](https://console.cloud.google.com/)

### GCP Project
Create a GCP project by given a project-id
- example: my-iot-project

### Increase quota for IP addresses
- Go to `IAM and Administration/quota/` (as indicated below)
- Search for `In-use IP addresses` and request to increase quota from 8 IP to 20 IP
- Unfortunately, it takes almost two days to be validated by GCP 

![Increase number of external IP](documents/increase-ip-quota.png)
     
### Get private key file
- Go to `IAM and Administration/quota/` (as indicated below)
- Create a service account if it is not already done
- Download private key file to be used in gitlab CICD. Indeed, store the content as global environment variable `PRIVATE_KEY_FILE_CONTENT`

![Private key file](documents/get-private-key-file.png)

### Give admin role to your service account
- Go to `IAM and Administration/IAM/` (as indicated below)
- Give role `owner` to your service account to be able to deploy with Gitlab CICD

![Admin role for service account](documents/give_admin_role_to_service_account.png)
     
## Architecture of IoT platform 

First we divide our plateform into microservices, here below the representation:

![Architecture of IoT Project](documents/microservices.png)

- Device management: manage reception of data from device
- Notification: send a notification (for example: email) to some users when a data received exceeds some thresholds
- Storage: store data received in different data storages
- Data processing: Predefined Batch processes
- Data Access: Expose data to users through API REST

The corresponding architecture we build to solve the previous representation is as below:

![Architecture of IoT Project](documents/architecture.png)

## Configure IoT platform 

### Environment variables

To deploy all application either with the Gitlab CICD pipeline (see the following picture to know where) or  with `deploy/deployer.sh` cli , you have to set the following environment variables:

    PROJECT_ID="your-project-id"
    COMPUTE_ZONE="your-selected-zone"  # for instance europe-west1-b
    COMPUTE_REGION="your-selected-region"  # for instance europe-west1
    CONTAINER_REPOSITORY="your docker repository"  # for instance eu.gcr.io
    PROJECT_NAME="your project name on gcp"  # for instance my-iot-platform
    PROJECT_ID="your project id on gcp"  # for instance my-iot-platform
    CLUSTER_NAME="name for the cluster" # for instance smart-agriculture-cluster
    COMPUTE_ZONE="your-selected-zone" # for instance europe-west2-b
    COMPUTE_REGION="your-selected-region" # for instance europe-west2
    CONTAINER_REPOSITORY="your docker repository" # for instance eu.gcr.io/my-iot-platform
    S3A_ACCESS_KEY="access-key-for-minio" # for instance AKIAIOSFODNN7EXBMJLE
    S3A_SECRET_KEY="access-key-for-minio" # for instance wHalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    MQTT_INDEXER_PASS="password-for-user-indexer-into-vernemq" # for instance 3ywbCs2uB4
    MQTT_NOTIFIER_PASS="password-for-user-notifier-into-vernemq"  # for instance qvQsSpg3tk
    MQTT_DEVICE_PASS="password-for-user-device-into-vernemq"  # for instance 9Fex2nqdqe
    ES_TRUSTORE_PASS="password-for-trustore-generated-for-spark-elasticsearch"  # for instance ChI2OfIpGuq0be5X
    MINIO_TRUSTORE_PASS="password-for-trustore-generated-for-spark-minio"  # for instance vkM8ssfK5fv4JQ9k

![Set environment variables in Gitlab](documents/set_environment_variables_in_gitlab.png)


### Run unit tests for IoT Platform with command lines

Run the following script to run all unit tests:

    ./deploy/deployer.sh test-unit


### Install IoT Platform with command lines

Run the following command to allocate external static IP addresses and create localy self signed ssl certificates

    ./deploy/deployer.sh create-certificates <environment> # 

Then, either run the following script to install this IoT platform on your GCP Account:

    ./deploy/deployer.sh setup-cluster # create Kuberntes cluster
    ./deploy/deployer.sh deploy-modules <environment> # Deploy all modules 
    
Or use the gitlab ci thanks to the `gitlab-ci.yaml` file
    
### Delete IoT Platform with command lines

Run the following script to delete the IoT platform on your GCP Account:

    ./deploy/deployer.sh delete-all