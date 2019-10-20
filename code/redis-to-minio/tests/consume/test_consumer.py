import os
import json
import time
import unittest
from common.common_redis import get_redis_client
from consume.consumer import TOPIC, get_messages_stored_in_a_file


class TestConsumer(unittest.TestCase):

    def setUp(self):
        # run a Redis broker within a docker container
        os.environ["TIMEOUT_CONSUMER"] = "5"
        prefix_path = os.popen("pwd").read()
        os.environ["PREFIX_PATH"] = prefix_path.replace("\n", "")
        os.environ["REDIS_HOST"] = "localhost"
        os.environ["REDIS_PORT"] = "6379"
        os.system("docker run -d -p 6379:6379 redis")
        os.system("sleep 3")  # wait container to be available

    def tearDown(self):
        container_ids = "$(docker ps -a -q  --filter ancestor=redis)"
        os.system(f"docker container stop {container_ids}")
        os.system(f"docker container rm {container_ids}")

    def test_get_messages_in_a_file(self):
        # Given
        redis_client = get_redis_client()
        message = {"key": "value"}
        for i in range(0, 5):
            time.sleep(0.001)
            redis_client.rpush(TOPIC, json.dumps(message))

        # When
        file_path = get_messages_stored_in_a_file(redis_client)
        content = os.popen("cat " + file_path).read()

        ## Then
        expected_content = json.dumps(message) + "\n" + \
                           json.dumps(message) + "\n" + \
                           json.dumps(message) + "\n" + \
                           json.dumps(message) + "\n" + \
                           json.dumps(message) + "\n"

        self.assertEqual(content, expected_content)
        os.system("rm -f " + file_path)
