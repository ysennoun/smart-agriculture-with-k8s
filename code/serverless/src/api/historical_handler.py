import os
import docker

DOCKER_IMAGE = os.environ["DOCKER_IMAGE"]
DOCKER_HOST = os.environ["DOCKER_HOST"]
PREFIX_SPARK_JOB_RESULT = os.environ["PREFIX_SPARK_JOB_RESULT"]


def get() -> str:
    client = docker.from_env()
    container = client.containers.run(DOCKER_IMAGE)
    for log in container.logs(stream=True):
        if log.startswith(PREFIX_SPARK_JOB_RESULT):
            return log.strip(PREFIX_SPARK_JOB_RESULT)
    return None
