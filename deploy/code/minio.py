import os
import sys
from minio import Minio


def get_minio_client(endpoint, access_key, secret_key):
    return Minio(endpoint,
               access_key=access_key,
               secret_key=secret_key)


def put_object(client, bucket_name, object_name, file_path):
    client.fput_object(bucket_name, object_name, file_path)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Error, wrong number of arguements, it should be 3")
        sys.exit(1)

    minio_endpoint = "10.0.12.116:9000" #os.environ["MINIO_ENDPOINT"]
    minio_access_key = "AKIAIOSFODNN7EXAMPLE" #os.environ["MINIO_ACCESS_KEY"]
    minio_secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" #os.environ["MINIO_SECRET_KEY"]
    bucket_name, object_name, file_path = sys.argv

    minio_client = get_minio_client(minio_endpoint, minio_access_key, minio_secret_key)
    put_object(minio_client, bucket_name, object_name, file_path)
