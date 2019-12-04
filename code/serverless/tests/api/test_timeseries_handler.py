import os
import json
import unittest
from influxdb import InfluxDBClient
from common.storage.influxdb_client import InfluxDBIoTClient
from api.timeseries_handler import get


class TestTimeseriesHandler(unittest.TestCase):

    session = None

    def _get_points(self, data):
        return [
            {
                "measurement": "smart_agriculture",
                "tags": {
                    "host": "server01",
                    "region": "us-west"
                },
                "time": "2009-11-10T23:00:00Z",
                "fields": data
            }
        ]

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

    def tests_validate_data(self):
        wrong_data = {"devicefake": "wrong"}

        result = get(wrong_data)
        self.assertEqual(result.status_code, 400)

    def test_insert_new_timeseries(self):

        data1 = {
            "device": "devicetest1234",
            "timestamp": 1568559650,
            "temperature": 23,
            "humidity": 56.8,
            "moisture": 9.21
        }
        data2 = {
            "device": "devicetest1234",
            "timestamp": 1568559670,
            "temperature": 23,
            "humidity": 56.8,
            "moisture": 9.21
        }
        client: InfluxDBClient = InfluxDBIoTClient().get_client()
        client.write_points(self._get_points(data1))
        client.write_points(self._get_points(data2))

        # only get data2
        data = {
            "device": "devicetest1234",
            "startAt": 1568559655,
            "endAt": 1568559675
        }

        result = get(data)
        expected_result = [{
            "device": "devicetest1234",
            "host": "server01",
            "region": "us-west",
            "time": "2009-11-10T23:00:00Z",
            "timestamp": 1568559670,
            "temperature": 23,
            "humidity": 56.8,
            "moisture": 9.21
        }]
        self.assertEqual(json.loads(result.get_data()), expected_result)