import paho.mqtt.client as mqtt
from common.utils.logger import Logger
from notification.device_handler import DeviceHandler

logger = Logger().get_logger()

if __name__ == "__main__":
    try:
        mqtt_client = mqtt.Client()
        device_handler = DeviceHandler(mqtt_client)
        device_handler.run()
    except Exception as ex:
        logger.error(f"Mqtt client failed: {str(ex)}")
