import paho.mqtt.client as mqtt
from common.utils.logger import Logger
from handler.publisher import Publisher
from handler.producer import Producer

logger = Logger().get_logger()


if __name__ == "__main__":
    try:
        mqtt_client = mqtt.Client(protocol=mqtt.MQTTv311)
        publisher = Publisher(mqtt_client=mqtt_client)
        producer = Producer()
        while True:
            publisher.publish_payload(paylaod=producer.get_payload())
            publisher.wait()

    except Exception as ex:
        logger.error(f"Device failed: {str(ex)}")
