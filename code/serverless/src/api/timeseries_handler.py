import json
from jsonschema import validate
from jsonschema import ValidationError
from flask import Response
from common.utils.logger import Logger
from common.storage.influxdb_client import InfluxDBIoTClient


logger = Logger().get_logger()


DATA_SCHEMA = {
    "type": "object",
    "properties":  {
        "device": {"type": "string"},
        "startAt": {"type": "number"},
        "endAt": {"type": "number"}
    },
    "required": ["device", "startAt", "endAt"]
}
TABLE = "smart_agriculture"
query = "select * FROM {table} WHERE device = '{device}' AND timestamp >= {start_at} AND timestamp <= {end_at};"


def get(data):
    try:
        validate(data, DATA_SCHEMA)
        device = data["device"]
        start_at = data["startAt"]
        end_at = data["endAt"]
        client = InfluxDBIoTClient().get_client()
        result = client.query(
            query.format(
                table=TABLE,
                device=device,
                start_at=start_at,
                end_at=end_at
            )
        )
        logger.info("Result: {0}".format(result))
        return Response(
            json.dumps(list(result.get_points())),
            status=200,
            mimetype='application/json'
        )
    except ValidationError as err:
        logger.error(str(err))
        return Response(str(err), status=400)
    except Exception as ex:
        logger.error(str(ex))
        return Response("Internal Error", status=500)

