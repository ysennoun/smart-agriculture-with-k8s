package com.xebia.iot.data

import java.sql.Timestamp

case class Point(device: String,
                 timestamp: Timestamp,
                 temperature: Double,
                 humidity: Double,
                 moisture: Double,
                 historicalJobDone: Boolean,
                 year: Int,
                 month: Int,
                 day: Int)

case class AveragePointByDeviceAndDate(device: String,
                 temperature: Double,
                 humidity: Double,
                 moisture: Double,
                 year: Int,
                 month: Int,
                 day: Int)

case class PointValuesSummed(temperature: Double,
                             humidity: Double,
                             moisture: Double,
                             count: Int)

case class DeviceAndDate(device: String, year: Int, month: Int, day: Int)
case class PointValuesSummedByDeviceAndDay(deviceAndDate: DeviceAndDate, pointValuesSummed: PointValuesSummed)
