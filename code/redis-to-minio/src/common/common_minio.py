from minio import Minio
from common import env


def get_minio_client() -> Minio:
    return Minio(
        endpoint=env.get_minio_endpoint(),
        access_key=env.get_minio_access_key(),
        secret_key=env.get_minio_secret_key(),
        secure=True)