import json
from connector import env
import paho.mqtt.client as mqtt
from common.serverless.kn_broker_client import send_to_broker
from common.utils.logger import Logger

logger = Logger().get_logger()


class MqttClient:

    def on_connect(self, client, userdata, flags, rc):
        logger.info(f"Connected with result code {str(rc)}")
        client.subscribe(env.get_topic_name())

    def on_message(self, client, userdata, msg):
        logger.info(f"message {str(msg.payload)} from topic {msg.topic}")
        data = json.loads(msg.payload.decode('UTF-8'))  # TODO decode hexadecimal to json
        brokers_url = env.get_brokers_url()
        for broker_url in brokers_url:
            send_to_broker(broker_url, data)
        logger.info("end on_message")

    def run(self):
        client = mqtt.Client()
        client.on_connect = self.on_connect
        client.on_message = self.on_message

        service_name = env.get_service_name()
        namespace_name = env.get_namespace_name()
        host = env.get_host(service_name, namespace_name)
        port = env.get_port()
        keep_alive = env.get_keep_alive()
        client.connect(host, port, keep_alive)
        client.loop_forever()


if __name__ == "__main__":
    try:
        mqtt_client = MqttClient()
        mqtt_client.run()
    except Exception as ex:
        logger.error(f"Mqtt client failed: {str(ex)}")