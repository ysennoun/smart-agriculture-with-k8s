from common.env import get_threshold_temperature
from common.env import get_threshold_humidity
from common.env import get_threshold_moisture
from common.utils.logger import Logger

logger = Logger().get_logger()

DATA_SCHEMA = {
    "type": "object",
    "properties":  {
        "device": {"type": "string"},
        "timestamp": {"type": "number"},
        "temperature": {"type": "number"},
        "humidity": {"type": "number"},
        "moisture": {"type": "number"},
    },
}


def trigger_alert(data):
    logger.info(f"trigger_alert, data: {data}")
    temperature = data["temperature"]
    humidity = data["humidity"]
    moisture = data["moisture"]

    if temperature >= get_threshold_temperature() or \
        humidity <= get_threshold_humidity() or \
        moisture <= get_threshold_moisture():

        logger.info(f"Trigger alert for data: {data}")
        #TODO send alert
        pass


def save(data):
    logger.info(f"Save data: {data}")
    #TODO save data in relational database and object store
    pass   