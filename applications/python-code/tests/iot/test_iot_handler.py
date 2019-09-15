import unittest

from iot.iot_handler import handler, trigger_alert, save


class TestIoTHandler(unittest.TestCase):

    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_handler(self):
        data = {
            "device": "smart-device",
            "timestamp": 1568043219,
            "temperature": 32,
            "humidity": 76,
            "moisture": 44
        }
        result = trigger_alert(data)
        self.assertEqual(result, None)

    def test_trigger_alert(self):
        data = {
            "device": "smart-device",
            "timestamp": 1568043219,
            "temperature": 32,
            "humidity": 76,
            "moisture": 44
        }
        result = trigger_alert(data)
        self.assertEqual(result, None)

    def test_save(self):
        data = {
            "device": "smart-device",
            "timestamp": 1568043219,
            "temperature": 32,
            "humidity": 76,
            "moisture": 44
        }
        result = save(data)
        self.assertEqual(result, None)