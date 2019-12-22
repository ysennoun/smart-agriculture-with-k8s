Feature: showing off behave

  Scenario: Send a IoT message to the platform and request through API the last value
     Given An IoT message is sent to the platform for device R2D2 with temperature 11 in topic iot/farming
       and An IoT message is sent to the platform for device R2D2 with temperature 12 in topic iot/farming
      When Request through API the last value for device R2D2
      Then For device R2D2, the temperature of the last value should be equal to 12


  Scenario: Send a IoT message to the platform and request through API the timeseries
     Given An IoT message is sent to the platform for device R2D2 with temperature 11 in topic iot/farming
       and An IoT message is sent to the platform for device R2D2 with temperature 12 in topic iot/farming
      When Request through API the timeseries for device R2D2
      Then For device R2D2, timeseries should contain 2 elements and temperatures should be
       | 11              |
       | 12              |
