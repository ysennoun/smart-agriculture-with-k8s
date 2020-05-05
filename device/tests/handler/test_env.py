import os
import pathlib
import unittest
from handler import env


class TestEnv(unittest.TestCase):

    @classmethod
    def get_resources_path(cls):
        return os.path.normpath(os.path.join(pathlib.Path(__file__).parent.absolute(), "..", "resources"))

    def setUp(self):
        os.environ["MQTT_CLIENT_ID_PATH"] = f"{self.get_resources_path()}/clientID"

    def test_should_get_client_id(self):
        # Given/When
        client_id = env.get_mqtt_client_id()

        # Then
        self.assertEqual(client_id, "device-test")