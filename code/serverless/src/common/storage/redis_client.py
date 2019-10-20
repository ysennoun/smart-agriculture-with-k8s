import os
import redis


def get_redis_host() -> str:
    return os.environ["REDIS_HOST"]


def get_redis_port() -> int:
    return int(os.environ["REDIS_PORT"])


def get_redis_client() -> redis:
    host = get_redis_host()
    port = get_redis_port()
    return redis.Redis(host=host, port=port, db=0)