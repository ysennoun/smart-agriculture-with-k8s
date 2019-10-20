from minio import Minio
from minio.error import (ResponseError, BucketAlreadyOwnedByYou,
                         BucketAlreadyExists)
from common import env


def create_bucket(minio_client: Minio):
    try:
        minio_client.make_bucket(
            bucket_name=env.get_bucket_name(),
            location=env.get_location())
    except BucketAlreadyOwnedByYou:
        pass
    except BucketAlreadyExists:
        pass
    except ResponseError as err:
        raise err


def upload_object(minio_client: Minio, file_path: str):
    try:
        minio_client.fput_object(
            bucket_name=env.get_bucket_name(),
            object_name=file_path,
            file_path=file_path
        )
    except ResponseError as err:
        print(err)



