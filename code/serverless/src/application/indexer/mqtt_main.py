import paho.mqtt.client as mqtt
from common.utils.logger import Logger
from indexer import env
from common.storage.elasticsearch_client import get_elasticsearch_client
from indexer.device_handler import DeviceHandler

logger = Logger().get_logger()

if __name__ == "__main__":
    try:
        mqtt_client = mqtt.Client()
        es_client = get_elasticsearch_client()
        es_alias = env.get_es_alias()
        device_handler = DeviceHandler(mqtt_client, es_client, es_alias)
        device_handler.run()
    except Exception as ex:
        logger.error(f"Mqtt client failed: {str(ex)}")
