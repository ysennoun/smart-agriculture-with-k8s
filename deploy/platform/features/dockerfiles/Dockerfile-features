FROM debian:jessie
MAINTAINER Yassir sennoun, ysennoun@xebia.fr

# Install system requirements
RUN apt-get update && apt-get install -y wget && apt-get install -y curl

# Install mosquitto clients
RUN apt-get update && apt-get install -y mosquitto-clients