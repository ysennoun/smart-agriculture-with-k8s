import os
from common import common_redis, common_minio
from consume import consumer
from sink import sinker


def delete_file(file_path: str):
    os.system(f"rm -f {file_path}")


def run():
    redis_client = common_redis.get_redis_client()
    minio_client = common_minio.get_minio_client()

    file_path = consumer.get_messages_stored_in_a_file(redis_client)
    sinker.create_bucket(minio_client)
    sinker.upload_object(minio_client, file_path)
    delete_file(file_path)


if __name__ == "__main__":
    try:
        while True:
            run()
    except Exception as ex:
        print(f"Mqtt client failed: {str(ex)}")