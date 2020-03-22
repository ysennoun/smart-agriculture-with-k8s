import os
from minio import Minio
from common.utils.logger import Logger

logger = Logger().get_logger()


def get_minio_endpoint():
    return os.environ["MINIO_ENDPOINT"]


def get_minio_bucket_name():
    return os.environ["MINIO_BUCKET_NAME"]


def get_minio_object_prefix():
    return os.environ["MINIO_OBJECT_PREFIX"]


def get_minio_access_key():
    password_path = os.environ["MINIO_ACCESS_KEY_PATH"]
    return open(password_path, 'r').read().rstrip('\n')


def get_minio_secret_key():
    password_path = os.environ["MINIO_SECRET_KEY_PATH"]
    return open(password_path, 'r').read().rstrip('\n')


def get_minio_client(endpoint, access_key, secret_key):
    return Minio(endpoint,
               access_key=access_key,
               secret_key=secret_key,
               secure=False)


def put_object(client, bucket_name):
    for file in os.listdir("."):
        if file.endswith(".jar"):
            logger.info(f"Put into Minio", extra={"file": file, "bucket_name": f"{bucket_name}/jars"})
            object_name = get_minio_object_prefix() + file
            client.fput_object(bucket_name, object_name, file)


if __name__ == "__main__":
    try:
        logger.info("Start putting jar files in minio")
        minio_endpoint = get_minio_endpoint()
        minio_access_key = get_minio_access_key()
        minio_secret_key = get_minio_secret_key()
        bucket_name = get_minio_bucket_name()
        minio_client = get_minio_client(minio_endpoint, minio_access_key, minio_secret_key)
        put_object(minio_client, bucket_name)
    except Exception as ex:
        logger.error("Put jars in minio failed", extra={"exception": str(ex)})

