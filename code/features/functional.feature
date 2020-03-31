Feature: Smart Agriculture

  Scenario: Send a IoT message to the platform and request through API the last value
     Given An IoT message is sent to the platform for device r2d1 with temperature 11 in topic iot/farming
       and An IoT message is sent to the platform for device r2d1 with temperature 12 in topic iot/farming
       and wait 2 min to let system handle data
      When Request through API the last value for device r2d1
      Then For device r2d1, the temperature of the last value should be equal to 12

  Scenario: Send a IoT message to the platform and request through API the timeseries
     Given An IoT message is sent to the platform for device rd2d with temperature 11 in topic iot/farming
       and An IoT message is sent to the platform for device rd2d with temperature 12 in topic iot/farming
       and wait 2 min to let system handle data
      When Request through API the timeseries for device rd2d
      Then For device rd2d, timeseries should contain 2 elements and temperatures should be
       | 11              |
       | 12              |
