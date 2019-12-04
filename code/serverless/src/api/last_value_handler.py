import json
from jsonschema import validate
from jsonschema import ValidationError
from flask import Response
from common.utils.logger import Logger
from common.storage.postgresql_client import PostgreSQLClient
from storage.last_value.model.last_value_model import LastValueModel


logger = Logger().get_logger()

DATA_SCHEMA = {
    "type": "object",
    "properties":  {
        "device": {"type": "string"}
    },
    "required": ["device"]
}


def get(data: dict) -> Response:

    try:
        validate(data, DATA_SCHEMA)
        session = PostgreSQLClient().get_session()
        device = data["device"]

        last_value_found = session.query(LastValueModel).filter(
            LastValueModel.device == device).first()

        result = json.dumps(last_value_found.get()) if last_value_found else "{}"
        return Response(result, status=200, mimetype='application/json')
    except ValidationError as err:
        logger.error(str(err))
        return Response(str(err), status=400)
    except Exception as ex:
        logger.error(str(ex))
        return Response("Internal Error", status=500)

