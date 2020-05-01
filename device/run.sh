#!/bin/bash

set -e

## FUNCTIONS
function configure_device(){
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
configure_device
