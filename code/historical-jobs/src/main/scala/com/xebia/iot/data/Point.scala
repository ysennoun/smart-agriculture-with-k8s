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