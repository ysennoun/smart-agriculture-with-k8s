import unittest

from application.back_end.exceptions.api_exceptions import APIError
from application.back_end.handlers import back_end_controller


class TestBackEndController(unittest.TestCase):

    def test_validate_good_body_request(self):
        ######### Given #########
        schema = {
            "type": "object",
            "properties": {
                "platform": {"type": "string", "format": "date-time"},
                "metric": {
                    "type": "array",
                    "items": {
                        "type": "number"
                    }
                }
            }
        }
        good_body_request = {
            "platform": "2018-11-13T20:20:39Z",
            "metric": [1, 2, 3]
        }

        ######### When #########
        validation_status = back_end_controller.validate_request(good_body_request, schema)

        ######### Then #########
        self.assertEqual(validation_status, None)

    def test_validate_wrong_body_request(self):
        ######### Given #########
        schema = {
            "type": "object",
            "properties": {
                "platform": {"type": "string"},
                "metric": {
                    "type": "array",
                    "items": {
                        "type": "number"
                    }
                }
            }
        }
        wrong_body_request = {
            "platform": 123,
            "metric": "metric"
        }

        ######### When/Then #########
        with self.assertRaises(APIError):
            back_end_controller.validate_request(wrong_body_request, schema)


if __name__ == "__main__":
    unittest.main()
