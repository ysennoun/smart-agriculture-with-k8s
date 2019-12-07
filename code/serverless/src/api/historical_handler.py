import os
import docker


def get_docker_image():
    return os.environ["DOCKER_IMAGE"]


def get_prefix_spark_job_result():
    return os.environ["PREFIX_SPARK_JOB_RESULT"]


def get() -> str:
    client = docker.from_env()
    container = client.containers.run(get_docker_image())
    for log in container.logs(stream=True):
        if log.startswith(get_prefix_spark_job_result()):
            return log.strip(get_prefix_spark_job_result())
