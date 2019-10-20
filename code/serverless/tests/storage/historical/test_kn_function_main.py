import os
import unittest


class TestKnFunctionMain(unittest.TestCase):

    session = None

    def setUp(self):
        # run a Redis broker within a docker container
        os.environ["REDIS_HOST"] = "localhost"
        os.environ["REDIS_PORT"] = "6379"
        os.system("docker run -d -p 6379:6379 redis")
        os.system("sleep 3")  # wait container to be available

    def tearDown(self):
        container_ids = "$(docker ps -a -q  --filter ancestor=redis)"
        os.system(f"docker container stop {container_ids}")
        os.system(f"docker container rm {container_ids}")

    def test_insert_new_historical(self):

        data = {
            "device": "devicetest",
            "timestamp": 1568559662,
            "temperature": 23,
            "humidity": 56.8,
            "moisture": 9.21
        }
        from storage.historical.kn_function_main import handler
        result = handler(data)
        self.assertEqual(str(result.get_data().decode("utf-8")), '{"status": "inserted"}')

