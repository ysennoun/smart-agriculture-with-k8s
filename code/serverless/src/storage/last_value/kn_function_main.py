import json
from datetime import datetime
from flask import Flask, request, Response
from common.env import get_port
from common.utils.logger import Logger
from common.storage.postgresql_client import PostgreSQLClient
from storage.last_value.model.last_value_model import LastValueModel


logger = Logger().get_logger()

app = Flask(__name__)
HOST = '0.0.0.0'
PORT = get_port()


def _get_status_response(status):
    return Response(
        json.dumps({"status": status}),
        status=200,
        mimetype="application/json"
    )


@app.route('/', methods=['POST'])
def handle_post():
    data = json.loads(request.form)
    logger.info(f"POST request, data: {data}")
    return handler(data)


def handler(data: dict) -> Response:
    session = PostgreSQLClient().get_session()
    device = data["device"]
    timestamp = data["timestamp"]
    temperature = data["temperature"]
    humidity = data["humidity"]
    moisture = data["moisture"]

    last_value_found = session.query(LastValueModel).filter(
        LastValueModel.device == device).first()
    if last_value_found:
        if last_value_found.timestamp >= datetime.fromtimestamp(timestamp):
            return _get_status_response("no action")
        else:
            last_value_found.timestamp = datetime.fromtimestamp(timestamp)
            last_value_found.temperature = temperature
            last_value_found.humidity = humidity
            last_value_found.moisture = moisture
            session.commit()
            return _get_status_response("updated")
    else:
        last_value = LastValueModel(
            device=device,
            timestamp=datetime.fromtimestamp(timestamp),
            temperature=temperature,
            humidity=humidity,
            moisture=moisture
        )
        session.add(last_value)
        session.commit()
        return _get_status_response("inserted")


if __name__ == "__main__":
    logger.info("main run")
    app.run(
        debug=True,
        host=HOST,
        port=PORT
    )



