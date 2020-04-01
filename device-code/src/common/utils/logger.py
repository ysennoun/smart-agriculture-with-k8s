import json
import logging


def _logger_schema():
    return json.dumps({
        "timestamp": "%(asctime)s",
        "level": "%(levelname)s",
        "name": "%(name)s",
        "message": "%(message)s",
    })


def _create_logging():
    logging.basicConfig(
        format=_logger_schema(),
        level=logging.INFO
    )
    return logging


class Logger:
    class __Logger:
        def __init__(self):
            self.logging = _create_logging()

        def __str__(self):
            return repr(self) + str(self.logging)

    instance = None

    def __init__(self):
        if not Logger.instance:
            Logger.instance = Logger.__Logger().logging

    def __getattr__(self, name):
        return getattr(self.instance, name)

    def get_logger(self):
        return self.instance
