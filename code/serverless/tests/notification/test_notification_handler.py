import os
import unittest
from notification import notification_handler


class TestNotificationHandler(unittest.TestCase):

    def test_notification_is_activated(self):
        ######### Given #########
        os.environ["THRESHOLD_TEMPERATURE"] = "25"
        os.environ["THRESHOLD_HUMIDITY"] = "35"
        os.environ["THRESHOLD_MOISTURE"] = "35"
        data = {
            "temperature": 30,
            "humidity": 30,
            "moisture": 30
        }

        ######### When #########
        is_activated = notification_handler.is_notification_activated(data)

        ######### Then #########
        expected_result = True
        self.assertEqual(is_activated, expected_result)

    def test_notification_is_not_activated(self):
        ######### Given #########
        os.environ["THRESHOLD_TEMPERATURE"] = "55"
        os.environ["THRESHOLD_HUMIDITY"] = "55"
        os.environ["THRESHOLD_MOISTURE"] = "55"
        data = {
            "temperature": 50,
            "humidity": 50,
            "moisture": 50
        }

        ######### When #########
        is_activated = notification_handler.is_notification_activated(data)

        ######### Then #########
        expected_result = False
        self.assertEqual(is_activated, expected_result)
