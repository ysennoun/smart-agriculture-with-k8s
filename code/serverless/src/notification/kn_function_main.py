from flask import Flask
from common.env import get_port
from common.utils.logger import Logger
from notification import notification_routes


logger = Logger().get_logger()
app = Flask(__name__)


if __name__ == "__main__":
    logger.info("main run")
    notification_routes.register_routes(app)
    app.run(
        debug=True,
        host='0.0.0.0',
        port=get_port()
    )
