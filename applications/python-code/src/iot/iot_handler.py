from jsonschema import validate
from jsonschema import ValidationError
from iot.env import get_threshold_temperature
from iot.env import get_threshold_humidity
from iot.env import get_threshold_moisture
from common.logger import get_logger

logger = get_logger()

DATA_SCHEMA = {
    "type" : "object",
    "properties" : {
        "device" : {"type" : "string"},
        "timestamp" : {"type" : "number"},
        "temperature" : {"type" : "number"},
        "humidity" : {"type" : "number"},
        "moisture" : {"type" : "number"},
    },
}


def handler(data):
    try:
        validate(instance=data, schema=DATA_SCHEMA)
        trigger_alert(data)
        save(data)
    except ValidationError as err:
        logger.error(f"WRONG ERROR FORMAT: {err}")
    except Exception as ex:
        logger.error(f"ERROR: {ex}")


def trigger_alert(data):
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