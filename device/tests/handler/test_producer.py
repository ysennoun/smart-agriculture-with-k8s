import unittest
from handler.producer import Producer


class TestProducer(unittest.TestCase):

    def test_should_convert_capacitive_moisture(self):
        # Given
        capacitive_moisture = 344

        # When
        percentage = Producer.convert_capacitive_moisture(capacitive_moisture)

        # Then
        self.assertEqual(percentage, 11)
