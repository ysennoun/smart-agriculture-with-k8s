# Project `smart-agriculture-with-k8s`

Build a smart agriculture project with Kubernetes

## Architecture of IoT platform 

First we divide our plateform into microservices, here below the representation:

![Architecture of IoT Project](documents/microservices.png)

- Device management: manage reception of data from device
- Storage: store data received in different data storages (Elasticsearch and Minio)
- Data processing: Predefined Batch processes
- Data Access: Expose data to users through API REST

The corresponding architecture we build to solve the previous representation is as below:

![Architecture of IoT Project](documents/architecture.png)

## How to begin ?

### Create a Gmail 
If you do not have a Gmail account, [follow this link](https://accounts.google.com/signup/v2/webcreateaccount?flowName=GlifWebSignIn&flowEntry=SignUp)

### GCP Account
Create a [GCP account](https://console.cloud.google.com/)

### GCP Project
Create a GCP project by given a project-id
- example: my-iot-project

### Requirements for project CLI

This project offers its own CLI `./deploy/deployer.sh` to test, create the cluster, deploy applications or delete all.

In case you want to use project CLI, you need to install:
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstarts), then run: `gcloud auth login`
- [helm](https://helm.sh/docs/intro/install/), the package manager for Kubernetes
- [Docker](https://docs.docker.com/get-docker/), configure Docker for a specific repository
    - Here we used GCP Container Repository: `gcloud auth configure-docker`
 
### Requirements for Gitlab CI/CD

This project offers the possibility to use a Gitlab CI/CD to test, create the cluster, deploy applications. See file `gitlab-ci.yaml`. 
   
#### Get private key file
- Go to `IAM and Administration/quota/` (as indicated below)
- Create a service account if it is not already done
- Download private key file to be used in gitlab CI/CD. Indeed, store the content as global environment variable `PRIVATE_KEY_FILE_CONTENT`

![Private key file](documents/get-private-key-file.png)

#### Give admin role to your service account
- Go to `IAM and Administration/IAM/` (as indicated below)
- Give role `owner` to your service account to be able to deploy with Gitlab CI/CD

![Admin role for service account](documents/give_admin_role_to_service_account.png)

#### Environment variables 

To deploy all application either with the Gitlab CI/CD pipeline (see the following picture to know where) or  with `deploy/deployer.sh` cli , you have to set the following environment variables:

    PROJECT_ID: "your-project-id"
    COMPUTE_ZONE: "your-selected-zone"  # for instance europe-west1-b
    COMPUTE_REGION: "your-selected-region"  # for instance europe-west1
    CONTAINER_REPOSITORY: "your docker repository"  # for instance eu.gcr.io
    PROJECT_NAME: "your project name on gcp"  # for instance my-iot-platform
    PROJECT_ID: "your project id on gcp"  # for instance my-iot-platform
    CLUSTER_NAME: "name for the cluster" # for instance smart-agriculture-cluster
    COMPUTE_ZONE:"your-selected-zone" # for instance europe-west2-b
    COMPUTE_REGION: "your-selected-region" # for instance europe-west2
    CONTAINER_REPOSITORY: "your docker repository" # for instance eu.gcr.io/my-iot-platform
    S3A_ACCESS_KEY: "access-key-for-minio" # for instance AKIAIOSFODNN7EXBMJLE
    S3A_SECRET_KEY: "access-key-for-minio" # for instance wHalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    MQTT_INDEXER_PASS: "password-for-user-indexer-into-vernemq" # for instance 3ywbCs2uB4
    MQTT_DEVICE_PASS: "password-for-user-device-into-vernemq"  # for instance 9Fex2nqdqe
    ES_TRUSTORE_PASS: "password-for-trustore-generated-for-spark-elasticsearch"  # for instance ChI2OfIpGuq0be5X
    MINIO_TRUSTSTORE_PASS: "password-for-trustore-generated-for-spark-minio"  # for instance vkM8ssfK5fv4JQ9k
    API_USER_PASS: "passwor-for-api" # for instance 4hxGaN34KQ

![Set environment variables in Gitlab](documents/set_environment_variables_in_gitlab.png)

### Deployment

#### Run unit tests for IoT Platform with command lines

Run the following script to run all unit tests:

    ./deploy/deployer.sh test-unit

#### Install IoT Platform (Command lines or Gitlab CI/CD)

Run the following command to allocate external static IP addresses and create locally self signed ssl certificates

    ./deploy/deployer.sh create-certificates <environment>

Then, either use the cli to install this IoT platform on your GCP Account:

    ./deploy/deployer.sh setup-cluster # create Kuberntes cluster
    ./deploy/deployer.sh deploy-modules <environment> # Deploy all modules 
    
Or use the gitlab ci thanks to the `gitlab-ci.yaml` file. (Add, commit and push into the branch <environment> or master)
    
#### Delete IoT Platform with command lines

Run the following script to delete the IoT platform on your GCP Account:

    ./deploy/deployer.sh delete-all
    
### Visualize Data

#### Add certificate to Chrome

Open chrome and go to `chrome://settings/`. Then, search for HTTPS/SSL in order to add certificate `deploy/cluster/certificates/api/tls.crt`.

#### Access to front end (see images below)

Run the following command to get the front end application ip address:

    ./deploy/deployer.sh get-front-end-ip <environment>
    
In chrome go to the following URL `http://<front-end-ip>:8080`. 

In the login page, enter:

    login="api"
    password=<API_USER_PASS>

![Login page](documents/login-page.png)

![Content page](documents/content-page.png)

### Device
 
Raspberry Pi is used as smart device. The architecture image above shows how this device retrieves code within a docker image in order to compute data and sent it to the platform.

To configure Raspberry Pi, first run the following command to create a service account to let device to access to Google Docker Registry.
The role associated to this service account has only read policy on this registry.

    ./deploy/deployer.sh create-device-service-account-and-roles
    
Then run the command below to generate a key to store as `key.json` file. This file will be installed in the Raspberry Pi.

    ./deploy/deployer.sh get-device-service-account-key
    
Finally, follow instructions indicated in `device/README.md`.