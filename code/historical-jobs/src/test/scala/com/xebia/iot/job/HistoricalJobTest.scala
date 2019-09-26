package com.xebia.iot.job

import java.sql.Timestamp
import java.util.Calendar

import com.xebia.iot.date.Timestamps
import com.xebia.iot.utils.SparkTestUtils
import org.apache.spark.sql.Dataset
import org.scalatest.{FlatSpec, Matchers}


class HistoricalJobTest  extends FlatSpec with Matchers with SparkTestUtils {

  "From Points data" should "be correctly convert into MeanOfPoints data" in {
    // Given
    import spark.implicits._
    val timestamps = Timestamps.getTimestamps()
    val timestamp1 = new Timestamp(timestamps.timestampAtMidnight.getTime - 3600*1000L) //hour=1
    val timestamp2 = new Timestamp(timestamps.timestampAtMidnight.getTime - 12*3600*1000L) //hour=14
    val timestamp3 = new Timestamp(timestamps.timestampAtMidnight.getTime - 3*3600*1000L) //hour=23
    println(timestamp1)
    println(timestamp2)
    println(timestamp3)
    val dataSet: Dataset[Point] = Seq(
      Point(device="device1", timestamp=timestamp1, temperature=1, humidity=1, moisture=1),
      Point(device="device2", timestamp=timestamp2, temperature=1, humidity=1, moisture=1),
      Point(device="device1", timestamp=timestamp1, temperature=2, humidity=2, moisture=2),
      Point(device="device1", timestamp=timestamp3, temperature=3, humidity=3, moisture=3),
      Point(device="device2", timestamp=timestamp2, temperature=2, humidity=2, moisture=2)
    ).toDS()



    // While
    val outputDataFrame = HistoricalJob.getDataSetAsMeanOfPoint(dataSet)

    // Then
    val timestampFrom: Timestamp = timestamps.timestampAtMidnightAWeekAgo
    val timestampTo: Timestamp = timestamps.timestampAtMidnight
    val calendar = Calendar.getInstance()
    calendar.setTimeInMillis(timestampTo.getTime)
    val expectedYear = calendar.get(Calendar.YEAR)
    val expectedMonth = calendar.get(Calendar.MONTH) + 1 //https://stackoverflow.com/questions/39771252/how-to-get-current-date-month-year-in-scala
    val expectedDay = calendar.get(Calendar.DAY_OF_MONTH)

    val expectedResult = Seq(
      MeanOfPoints(device="device1", hour=1, timestampFrom=timestampFrom, timestampTo=timestampTo, meanTemperature=1.5, meanHumidity=1.5, meanMoisture=1.5, year=expectedYear, month=expectedMonth, day=expectedDay),
      MeanOfPoints(device="device2", hour=14, timestampFrom=timestampFrom, timestampTo=timestampTo, meanTemperature=1.5, meanHumidity=1.5, meanMoisture=1.5, year=expectedYear, month=expectedMonth, day=expectedDay),
      MeanOfPoints(device="device1", hour=23, timestampFrom=timestampFrom, timestampTo=timestampTo, meanTemperature=3, meanHumidity=3, meanMoisture=3, year=expectedYear, month=expectedMonth, day=expectedDay)
    )
    outputDataFrame.show()
    outputDataFrame.collect().toSeq should contain theSameElementsAs expectedResult

  }
}