import os
import uuid
import datetime
import requests
from common.utils.logger import Logger

logger = Logger().get_logger()


_TIMEOUT = 7


def get_headers():
    return {
        "Content-Type": "application/json",
        "X-B3-Flags": "1",
        "CE-Type": os.environ["CE-Type"],
        "CE-Time": f"{datetime.datetime.now():%Y-%m-%dT%H:%M:%SZ}",
        "CE-Id": str(uuid.uuid4()),
        "CE-Source": "iot.knative",
        "CE-SpecVersion": "0.2"
    }


def send_to_broker(broker_url, data):
    try:
        result = requests.post(
                url=broker_url,
                headers=get_headers(),
                data=data,
                timeout=_TIMEOUT
            )
        logger.info(f"INVOKE broker {broker_url}: {result.text}")
        return result
    except Exception as ex:
        logger.error(f"ERROR broker: {ex}")
        raise ex
