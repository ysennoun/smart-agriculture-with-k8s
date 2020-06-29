import json
from common.utils.logger import Logger
from common.utils.date import get_current_date
from handler import env

logger = Logger().get_logger()

class Producer:

    def __init__(self):
        # add imports here to run unit tests in none Raspberry Pi environment 
import busio
from board import SCL, SDA
from adafruit_seesaw.seesaw import Seesaw
i2c_bus = busio.I2C(SCL, SDA)
self.seesaw = Seesaw(i2c_bus, addr=0x36)
        self.client_id = env.get_mqtt_client_id()

    @classmethod
    def convert_capacitive_moisture(cls, capacitive_moisture: float) -> float:
        # capacitive moisture in wet condition is 700 and capacitive moisture in dry condition is 300
        # consider linear relation => y = a * x + b where a = 0.25 and b = -75
        return 0.25 * capacitive_moisture - 75

    def get_temperature(self) -> float:
        return float(self.seesaw.get_temp())

    def get_moisture(self) -> float:
        return self.convert_capacitive_moisture(self.seesaw.moisture_read())

    def get_payload(self) -> str:
        payload = {
            "device": self.client_id,
            "timestamp": get_current_date(),
            "temperature": self.get_temperature(),
            "moisture": self.get_moisture()
        }
        logger.info("Get payload", extra={"payload": payload})
        return json.dumps(payload)
