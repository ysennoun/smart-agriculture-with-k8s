package com.xebia.iot.date

import java.sql.Timestamp
import java.util.Date

case class Timestamps(timestampAtMidnight: Timestamp,
                      timestampAtMidnightAWeekAgo: Timestamp)

object Timestamps{

  def getTimestamps(): Timestamps = {
    val currentTimestamp = new Date().getTime
    val weekDuration = 3600*1000*24*7
    val timestampAtMidnight = new Date(currentTimestamp - currentTimestamp % (24 * 60 * 60 * 1000)).getTime
    val timestampAtMidnightAWeekAgo = timestampAtMidnight - weekDuration
    Timestamps(new Timestamp(timestampAtMidnight), new Timestamp(timestampAtMidnightAWeekAgo))
  }
}