import os
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

    def test_insert_new_last_value(self):

        data = {
            "device": "devicetest",
            "timestamp": 1568559662,
            "temperature": 23,
            "humidity": 56.8,
            "moisture": 9.21
        }
        from storage.last_value.kn_function_main import handler
        result = handler(data)
        self.assertEquals(result, "inserted")

    def test_update_last_value_for_higher_timestamp(self):
        from storage.last_value.model.last_value_model import LastValueModel
        from storage.last_value.kn_function_main import handler
        old_data = LastValueModel(
            device="devicetest",
            timestamp=datetime.fromtimestamp(1568559662),
            temperature=12,
            humidity=23,
            moisture=11
        )
        self.session.add(old_data)
        self.session.commit()
        new_data = {
            "device": "devicetest",
            "timestamp": 1568559675,
            "temperature": 23,
            "humidity": 56.8,
            "moisture": 9.21
        }
        result = handler(new_data)
        self.assertEquals(result, "updated")

    def test_no_update_last_value_for_lower_timestamp(self):
        from storage.last_value.model.last_value_model import LastValueModel
        from storage.last_value.kn_function_main import handler
        old_data = LastValueModel(
            device="devicetest",
            timestamp=datetime.fromtimestamp(1568559662),
            temperature=12,
            humidity=23,
            moisture=11
        )
        self.session.add(old_data)
        self.session.commit()
        new_data = {
            "device": "devicetest",
            "timestamp": 1568559650,
            "temperature": 23,
            "humidity": 56.8,
            "moisture": 9.21
        }
        result = handler(new_data)
        self.assertEquals(result, None)


