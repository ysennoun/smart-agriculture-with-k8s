package com.xebia.iot.utils

import java.sql.Timestamp

import org.scalatest.{FlatSpec, Matchers}

class CustomDateTest extends FlatSpec with Matchers {

  "From a timestamp, it" should "get timestamps at midnight for the same day and a week before" in {
    // Given
    val timestampInMilliSeconds = 1569704116000L // 28 September 2019

    // Then
    val timestamps: Timestamps = CustomDate.getTimestampsOverAWeek(timestampInMilliSeconds)

    // When
    val expectedTimestamps = Timestamps(
      timestampAtMidnight=new Timestamp(1569628800000L),
      timestampAtMidnightAWeekAgo=new Timestamp(1569024000000L)
    )
    timestamps should equal(expectedTimestamps)
  }

  "From a timestamp, it" should "get year, month and day" in {
    // Given
    val timestampInMilliSeconds = 1569704116000L // 28 September 2019

    // Then
    val dateInformation: DateInformation = CustomDate.getDateInformation(timestampInMilliSeconds)

    // When
    val expectedDateInformation = DateInformation(year=2019, month=9, day=28)
    dateInformation should equal(expectedDateInformation)
  }
}
