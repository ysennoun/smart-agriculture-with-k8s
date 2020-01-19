from mqtt.mqtt_client import MqttClient
from common.utils.logger import Logger

logger = Logger().get_logger()

if __name__ == "__main__":
    try:
        mqtt_client = MqttClient()
        mqtt_client.run()
    except Exception as ex:
        logger.error(f"Mqtt client failed: {str(ex)}")
