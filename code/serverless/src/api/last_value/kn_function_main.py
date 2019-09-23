import json
from jsonschema import validate
from jsonschema import ValidationError
from flask import Flask, request, Response
from common.env import get_port
from common.utils.logger import Logger
from common.storage.postgresql_client import PostgreSQLClient
from storage.last_value.model.last_value_model import LastValueModel


logger = Logger().get_logger()

app = Flask(__name__)
HOST = '0.0.0.0'
PORT = get_port()
DATA_SCHEMA = {
    "type": "object",
    "properties":  {
        "device": {"type": "string"}
    },
    "required": ["device"]
}


@app.route('/device/last-value', methods=['GET'])
def handle_post():
    data = request.form
    logger.info(f"GET request, data: {data}")
    return device_handler(data)


def device_handler(data: dict) -> Response:

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


if __name__ == "__main__":
    logger.info("main run")
    app.run(
        debug=True,
        host=HOST,
        port=PORT
    )



