package com.xebia.iot.utils

import java.sql.Timestamp
import java.util.{Calendar, Date}

case class Timestamps(timestampAtMidnight: Timestamp,
                      timestampAtMidnightAWeekAgo: Timestamp)

case class DateInformation(year: Int, month: Int, day: Int)

object CustomDate{

  def getCurrentTimestamp(): Long = {
    new Date().getTime
  }

  def getTimestampsOverAWeek(timestamp: Long): Timestamps = {
    val weekDuration = 3600*1000*24*7
    val timestampAtMidnight = new Date(timestamp - timestamp % (24 * 60 * 60 * 1000)).getTime
    val timestampAtMidnightAWeekAgo = timestampAtMidnight - weekDuration
    Timestamps(new Timestamp(timestampAtMidnight), new Timestamp(timestampAtMidnightAWeekAgo))
  }

  def getDateInformation(timestamp: Long): DateInformation ={
    val calendar = Calendar.getInstance()
    calendar.setTimeInMillis(timestamp)
    DateInformation(
      year=calendar.get(Calendar.YEAR),
      month=calendar.get(Calendar.MONTH) + 1,//https://stackoverflow.com/questions/39771252/how-to-get-current-date-month-year-in-scala
      day=calendar.get(Calendar.DAY_OF_MONTH)
    )
  }
}