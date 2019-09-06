import os

from connector import env
import paho.mqtt.client as mqtt
from common.kn_function_client import invoke_kn_function
from common.logger import get_logger

logger = get_logger()

def ww(line):
    with open("log.txt", "a") as fl:
        fl.write(line+"\n")

class MqttClient:


    # The callback for when the client receives a CONNACK response from the server.
    def on_connect(self, client, userdata, flags, rc):
        ww("Connected with result code "+str(rc))
        logger.info("Connected with result code "+str(rc))
        # Subscribing in on_connect() means that if we lose the connection and
        # reconnect then subscriptions will be renewed.
        ww(str(env.get_topic_name()))
        client.subscribe(env.get_topic_name())


    # The callback for when a PUBLISH message is received from the server.
    def on_message(self, client, userdata, msg):
        ww(msg.topic+" "+str(msg.payload))
        logger.info(msg.topic+" "+str(msg.payload))    
        logger.info("before invoke")  
        invoke_kn_function(
            kn_function_name=env.get_kn_function_name(),
            data=msg.payload
        )
        logger.info("after invoke")


    def run(self):
        client = mqtt.Client()
        client.on_connect = self.on_connect
        client.on_message = self.on_message

        service_name = env.get_service_name()
        namespace_name = env.get_namespace_name()
        host = env.get_host(service_name, namespace_name)
        port = env.get_port()
        keep_alive = env.get_keep_alive()
        ww(str(service_name))
        ww(str(host))
        ww(str(port))
        ww(str(keep_alive))
        client.connect(host, port, keep_alive)
        ww("after connect")
        # Blocking call that processes network traffic, dispatches callbacks and
        # handles reconnecting.
        # Other loop*() functions are available that give a threaded interface and a
        # manual interface.
        client.loop_forever()


if __name__ == "__main__":
    ww("main")
    mqtt_client = MqttClient()
    mqtt_client.run()