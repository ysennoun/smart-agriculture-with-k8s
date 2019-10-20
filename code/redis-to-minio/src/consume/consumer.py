import time, json
import redis
from common import env


TOPIC = "smart-agriculture"
FILE_PATH = "{prefix_path}/{topic}-{date}.json"


def wait():
    time.sleep(0.001)


def get_messages_stored_in_a_file(redis_client: redis) -> str:
    start = env.get_current_time()
    current_time = start
    end = start + env.get_timeout_consumer()
    prefix_path = env.get_prefix_path()
    file_path = FILE_PATH.format(
        prefix_path=prefix_path,
        topic=TOPIC,
        date=start)

    with open(file_path, "a") as file:
        while current_time < end:
            wait()
            current_time = env.get_current_time()
            message = redis_client.lpop(TOPIC)
            if message:
                file.write(message.decode("utf-8") + "\n")
    return file_path


