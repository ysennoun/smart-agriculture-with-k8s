import os
import unittest
from storage.timeseries.kn_function_main import handler


class TestKnFunctionMain(unittest.TestCase):

    session = None

    def setUp(self):
        # run a InfluxDB broker within a docker container
        os.environ["INFLUXDB_DB"] = "db0"
        os.environ["INFLUXDB_USER"] = "infludbuser"
        os.environ["INFLUXDB_USER_PASSWORD"] = "influxdbpassword"
        os.environ["INFLUXDB_HOST"] = "localhost"
        os.environ["INFLUXDB_PORT"] = "8086"
        os.system("docker run -d -p 8086:8086 \
            -e INFLUXDB_DB=db0 \
            -e INFLUXDB_USER=infludbuser -e INFLUXDB_USER_PASSWORD=influxdbpassword \
            -v $PWD:/var/lib/influxdb influxdb")
        os.system("sleep 3")  # wait container to be available

    def tearDown(self):
        container_ids = "$(docker ps -a -q  --filter ancestor=influxdb)"
        os.system(f"docker container stop {container_ids}")
        os.system(f"docker container rm {container_ids}")

    def test_insert_new_timeseries(self):

        data = {
            "device": "devicetest",
            "timestamp": 1568559662,
            "temperature": 23,
            "humidity": 56.8,
            "moisture": 9.21
        }

        try:
            handler(data)
            assert True
        except TypeError:
            assert False