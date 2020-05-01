import json
from common.utils.logger import Logger
from common.utils.date import get_current_date
from handler import env


logger = Logger().get_logger()

#https://docs.aws.amazon.com/fr_fr/iot/latest/developerguide/iot-moisture-raspi-setup.html
#https://learn.adafruit.com/adafruit-stemma-soil-sensor-i2c-capacitive-moisture-sensor/python-circuitpython-test
#https://www.planete-domotique.com/hat-gsm-gprs-gnss-bluetooth-pour-raspberry-pi-waveshare.html


class Producer:

    def __init__(self):
        self.client_id = env.get_mqtt_client_id()

    def get_temperature(self) -> int:
        return 11  # get measure from sensor

    def get_moisture(self) -> int:
        return 22  # get measure from sensor

    def get_payload(self) -> str:
        payload = {
            "device": self.client_id,
            "timestamp": get_current_date(),
            "temperature": self.get_temperature(),
            "moisture": self.get_moisture()
        }
        logger.info("Get payload", extra={"payload": payload})
        return json.dumps(payload)
