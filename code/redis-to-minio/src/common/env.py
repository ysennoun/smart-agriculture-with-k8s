import os
import time


def get_current_time() -> int:
    return int(time.time())


def get_timeout_consumer() -> int:
    return int(os.environ.get("TIMEOUT_CONSUMER", "300"))  # by default 5 min


def get_redis_host() -> str:
    return os.environ["REDIS_HOST"]


def get_redis_port() -> int:
    return int(os.environ["REDIS_PORT"])


def get_prefix_path() -> str:
    return os.environ["PREFIX_PATH"]


def get_minio_endpoint() -> str:
    return os.environ["MINIO_ENDPOINT"]


def get_minio_access_key() -> str:
    return os.environ["MINIO_ACCESS_KEY"]


def get_minio_secret_key() -> str:
    return os.environ["MINIO_SECRET_KEY"]


def get_bucket_name() -> str:
    return os.environ["BUCKET_NAME"]


def get_location() -> str:
    return os.environ["LOCATION"]