import os
import unittest
import time
import docker


class TestKnFunctionMain(unittest.TestCase):

    session = None
    __es_container = None

    def setUp(self):
        # run an Elasticsearch broker within a docker container
        os.environ["ELASTICSEARCH_ENDPOINT"] = "localhost:9200"
        client = docker.from_env()
        self.__es_container = client.containers.run(
            image="docker.elastic.co/elasticsearch/elasticsearch:7.5.1",
            ports={"9200/tcp": 9200, "9300/tcp": 9300},
            environment={"discovery.type": "single-node"},
            detach=True
        )
        time.sleep(20)  # wait container to be available

    def tearDown(self):
        if self.__es_container:
            self.__es_container.stop()
            self.__es_container.remove()

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

