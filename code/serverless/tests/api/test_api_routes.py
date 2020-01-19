import unittest
from unittest.mock import Mock
from api.api_routes import get_offset_and_max_results


class TestApiRoutes(unittest.TestCase):

    def test_get_offset_and_max_results(self):
        ######### Given #########

        request = Mock()
        request.args.get = Mock(return_value="11")

        ######### When #########
        offset, max_results = get_offset_and_max_results(request)

        ######### Then #########
        self.assertEqual(offset, 11)
        self.assertEqual(max_results, 11)


if __name__ == '__main__':
    unittest.main()