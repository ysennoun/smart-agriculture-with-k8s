import os
import unittest
from unittest.mock import patch, MagicMock
from api.historical_handler import get


class TestHistoricalHandler(unittest.TestCase):
    def setUp(self):
        os.environ["DOCKER_IMAGE"] = "docker_image:latest"
        os.environ["PREFIX_SPARK_JOB_RESULT"] = "prefix: "

    @patch("api.historical_handler.get_container_logs")
    def test_get_none_result(self, container_logs: MagicMock):
        ######### Given #########
        container_logs.return_value = ["log", "log", "log", "log"]

        ######### When #########
        result = get()
        ######### Then #########
        expected_result = None
        self.assertEqual(result, expected_result)

    @patch("api.historical_handler.get_container_logs")
    def test_get_result(self, container_logs: MagicMock):
        ######### Given #########
        container_logs.return_value = ["log", "log", "prefix: expected result", "log"]

        ######### When #########
        result = get()
        ######### Then #########
        expected_result = "expected result"
        self.assertEqual(result, expected_result)


if __name__ == '__main__':
    unittest.main()