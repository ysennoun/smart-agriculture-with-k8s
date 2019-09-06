import json
import logging


_LOG_FILE_NAME = 'logfile.log'

def _logger_schema():
    return json.dumps({
        "timestamp": "%(asctime)s",
        "level": "%(levelname)s",
        "name": "%(name)s",
        "message": "%(message)s",
    })

def get_logger():
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.WARNING)

    file_handler = logging.FileHandler(
        _LOG_FILE_NAME
        )
    formatter = logging.Formatter(
        _logger_schema()
    )
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
    
    return logger

    