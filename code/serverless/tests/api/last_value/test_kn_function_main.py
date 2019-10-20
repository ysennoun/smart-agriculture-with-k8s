import os
import json
import unittest
from datetime import datetime
from common.storage.postgresql_client import PostgreSQLClient


class TestKnFunctionMain(unittest.TestCase):

    session = None

    def setUp(self):
        # run a PostgreSQL broker within a docker container
        os.environ["POSTGRES_USER"] = "postgres"
        os.environ["POSTGRES_PASSWORD"] = "mysecretpassword"
        os.environ["POSTGRES_HOST"] = "localhost"
        os.environ["POSTGRES_PORT"] = "5432"
        os.environ["POSTGRES_DATABASE"] = "postgres"
        os.system("docker run --name some-postgres -p 5432:5432 -e POSTGRES_PASSWORD=mysecretpassword -d postgres")
        os.system("sleep 3")  # wait container to be available
        from storage.last_value.model.last_value_model import Base, LastValueModel
        client = PostgreSQLClient()
        engine = client.get_engine()
        engine.connect()
        Base.metadata.create_all(engine)
        self.session = client.get_session()

    def tearDown(self):
        container_ids = "$(docker ps -a -q  --filter ancestor=postgres)"
        os.system(f"docker container stop {container_ids}")
        os.system(f"docker container rm {container_ids}")

    def test_validate_data(self):
        wrong_data = {"devicefake": "wrong"}
        from api.last_value.kn_function_main import device_handler

        result = device_handler(wrong_data)
        self.assertEqual(result.status_code, 400)

    def test_get_last_value_for_device(self):
        from storage.last_value.model.last_value_model import LastValueModel
        last_value_1 = LastValueModel(
            device="devicetest1",
            timestamp=datetime.fromtimestamp(1568559650),
            temperature=15,
            humidity=25,
            moisture=15
        )
        last_value_2 = LastValueModel(
            device="devicetest2",
            timestamp=datetime.fromtimestamp(1568559650),
            temperature=12,
            humidity=23,
            moisture=11
        )
        self.session.add(last_value_1)
        self.session.add(last_value_2)
        self.session.commit()

        # only to get data1
        data = {
            "device": "devicetest1"
        }
        from api.last_value.kn_function_main import device_handler

        result = json.loads(device_handler(data).get_json())
        self.assertEqual(result["device"], "devicetest1")
        self.assertEqual(result["temperature"], 15)
        self.assertEqual(result["humidity"], 25)
        self.assertEqual(result["moisture"], 15)
