import os
import docker


def get_docker_image():
    return os.environ["DOCKER_IMAGE"]


def get_prefix_spark_job_result():
    return os.environ["PREFIX_SPARK_JOB_RESULT"]


def get_container_logs():
    client = docker.from_env()
    container = client.containers.run(get_docker_image())
    return container.logs(stream=True)


def get() -> str:
    for log in get_container_logs():
        if log.startswith(get_prefix_spark_job_result()):
            return log.replace(get_prefix_spark_job_result(), "")
