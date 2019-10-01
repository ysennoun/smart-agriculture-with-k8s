package com.xebia.iot.data

import java.sql.Timestamp

case class Point(device: String,
                 timestamp: Timestamp,
                 temperature: Double,
                 humidity: Double,
                 moisture: Double,
                 year: Int,
                 month: Int,
                 day: Int)

case class MeanOfPoints(device: String,
                        timestampFrom: Timestamp,
                        timestampTo: Timestamp,
                        hour: Int,
                        meanTemperature: Double,
                        meanHumidity: Double,
                        meanMoisture: Double,
                        year: Int,
                        month: Int,
                        day: Int)