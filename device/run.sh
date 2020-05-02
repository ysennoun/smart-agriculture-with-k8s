#!/bin/bash

set -e

ACTION=$1

## FUNCTIONS
usage() {
    echo "Run the script in current shell with . (dot) before. Usage:"
    echo " ." `basename "$0"` "<ACTION>"
    echo ""
    echo "ACTION:"
    echo "  - install-docker: install docker"
    echo "  - configure-device: configure device"
}

function install-docker(){
    curl -sSL get.docker.com -o get-docker.sh
    sh get-docker.sh && rm get-docker.sh
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
}

function configure-device(){
    # Configure credentials
    mkdir -p "/home/$USER/credentials"

    echo "pi" > "/home/$USER/credentials/clientId"
    echo -e "\n"

    echo "device" > "/home/$USER/credentials/username"
    echo -e "\n"

    read -s -p "Enter password for VerneMQ: " password
    echo "$password" > "/home/$USER/credentials/password"
    echo -e "\n" && unset password

    # Set cron job
    rm -f "/home/$USER/cron_job.sh"
    echo '#!/bin/bash' >> "/home/$USER/cron_job.sh"
    echo 'set -e' >> "/home/$USER/cron_job.sh"
    echo 'docker login -u _json_key -p "$(cat /home/$USER/credentials/key.json)" https://eu.gcr.io && \' >> "/home/$USER/cron_job.sh"
    echo 'docker pull eu.gcr/ysennoun-iot/device:latest && \' >> "/home/$USER/cron_job.sh"
    echo 'docker stop device-container || true && docker rm device-container || true && \' >> "/home/$USER/cron_job.sh"
    echo 'docker run --name device-container --device=/dev/gpiomem:/dev/gpiomem -v /home/$USER/credentials:/etc/credentials -it -d -p 8883:8883 device:latest' >> "/home/$USER/cron_job.sh"
    chmod 755 "/home/$USER/cron_job.sh"
    echo "0 2 * * * /home/$USER/cron_job.sh" > crontab.txt # every day at 2 am
    crontab crontab.txt
    rm -f crontab.txt
}

## RUN
fn_exists() {
  [[ `type -t $1`"" == 'function' ]]
}

main() {

    if [[ -n "$ACTION" ]]; then
        echo
    else
        usage
        exit 1
    fi

    if ! fn_exists "$ACTION"; then
        echo "Error: $ACTION is not a valid ACTION"
        usage
        exit 2
    fi

    # Execute action
    ${ACTION} "$@"
}

main "$@"
