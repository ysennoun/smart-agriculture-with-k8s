import redis
from common import env


def get_redis_client() -> redis:
    host = env.get_redis_host()
    port = env.get_redis_port()
    return redis.Redis(host=host, port=port, db=0)
