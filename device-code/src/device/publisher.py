import ssl
import time
import paho.mqtt.publish as publish
from common.utils.logger import Logger
from device import env


logger = Logger().get_logger()


class Publisher:

    def __init__(self, mqtt_client):
        self.client = mqtt_client
        self.topic = env.get_mqtt_topic()
        self.client_id = env.get_mqtt_client_id()
        self.host_ip = env.get_mqtt_host_ip()
        self.host_port = env.get_mqtt_host_port()
        self.keep_alive = env.get_keep_alive()
        self.auth = {
            "username": env.get_mqtt_username(),
            "password": env.get_mqtt_password()
        }
        self.tls = {
            "ca_certs": env.get_mqtt_ca_file(),
            "cert_reqs": ssl.CERT_REQUIRED,
            "tls_version": ssl.PROTOCOL_TLS
        }
        self.publishing_frequency = env.get_publishing_frequency()

    def wait(self):
        minutes = self.publishing_frequency * 60
        logger.info(f"Wait {minutes} minutes")
        time.sleep(minutes)

    def publish_payload(self, payload: str):
        logger.info("Publish paylod", extra={"hostname": self.host_ip, "port": self.host_port, "payload": payload})
        publish.single(self.topic, payload=payload,
                       hostname=self.host_ip, port=self.host_port,
                       client_id=self.client_id, keepalive=self.keep_alive,
                       auth=self.auth, tls=self.tls)

