import os
import json
import unittest
import requests_mock
from notification.notification_by_email import is_notification_activated


class TestNotificationByEmail(unittest.TestCase):

    def test_notification_is_activated(self):
        os.environ["THRESHOLD_TEMPERATURE"] = "25"
        os.environ["THRESHOLD_HUMIDITY"] = "35"
        os.environ["THRESHOLD_MOISTURE"] = "35"
        data = {
            "temperature": 30,
            "humidity": 30,
            "moisture": 30
        }

        is_activated = is_notification_activated(data)

        expected_result = True
        self.assertEqual(is_activated, expected_result)

    def test_notification_is_not_activated(self):
        os.environ["THRESHOLD_TEMPERATURE"] = "55"
        os.environ["THRESHOLD_HUMIDITY"] = "55"
        os.environ["THRESHOLD_MOISTURE"] = "55"
        data = {
            "temperature": 50,
            "humidity": 50,
            "moisture": 50
        }

        is_activated = is_notification_activated(data)

        expected_result = False
        self.assertEqual(is_activated, expected_result)
