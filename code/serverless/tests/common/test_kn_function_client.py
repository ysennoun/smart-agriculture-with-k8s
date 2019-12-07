import os
import unittest
 
import requests_mock
from common.kn_client.kn_function_client import invoke_kn_function


class TestKnFunctionClient(unittest.TestCase):
 
    def setUp(self):
        pass
 
    def tearDown(self):
        pass
 
    def test_invoke_kn_function(self):
        kn_function_name = "kn_function_name"
        data = {"data": "data"}
        istio_ip_address = "test.com"
        os.environ["ISTIO_INGRESS_GATEWAY_IP_ADDRESS"] = istio_ip_address
        expected_response = "response"
        
        with requests_mock.mock() as mocker:
            mocker.post('http://' + istio_ip_address, text=expected_response)
            result = invoke_kn_function(kn_function_name, data)
            self.assertEqual(result.text, expected_response)
 

if __name__ == "__main__":
    unittest.main()