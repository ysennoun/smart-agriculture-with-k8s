package com.xebia.iot.transformation

import java.sql.Timestamp

import com.xebia.iot.data.{MeanOfPoints, Point}
import com.xebia.iot.utils.CustomDate.{getCurrentTimestamp, getTimestampsOverAWeek}
import com.xebia.iot.utils.{CustomDate, SparkTestUtils}
import org.apache.spark.sql.Dataset
import org.scalatest.{FlatSpec, Matchers}


class PointsTransformationTest extends FlatSpec with Matchers with SparkTestUtils {

  "From Points data" should "be correctly convert into MeanOfPoints data" in {
    // Given
    import spark.implicits._
    val currentTimestamp = getCurrentTimestamp()
    val timestamps = getTimestampsOverAWeek(currentTimestamp)
    val timestamp1 = new Timestamp(timestamps.timestampAtMidnight.getTime - 3600*1000L) //hour=1
    val timestamp2 = new Timestamp(timestamps.timestampAtMidnight.getTime - 12*3600*1000L) //hour=14
    val timestamp3 = new Timestamp(timestamps.timestampAtMidnight.getTime - 3*3600*1000L) //hour=23
    val timestampFrom: Timestamp = timestamps.timestampAtMidnightAWeekAgo
    val timestampTo: Timestamp = timestamps.timestampAtMidnight
    val dateInfo = CustomDate.getDateInformation(timestampTo.getTime)
    val dataSet: Dataset[Point] = Seq(
      Point(device="device1", timestamp=timestamp1, temperature=1, humidity=1, moisture=1, year=dateInfo.year, month=dateInfo.month, day=dateInfo.day),
      Point(device="device2", timestamp=timestamp2, temperature=1, humidity=1, moisture=1, year=dateInfo.year, month=dateInfo.month, day=dateInfo.day),
      Point(device="device1", timestamp=timestamp1, temperature=2, humidity=2, moisture=2, year=dateInfo.year, month=dateInfo.month, day=dateInfo.day),
      Point(device="device1", timestamp=timestamp3, temperature=3, humidity=3, moisture=3, year=dateInfo.year, month=dateInfo.month, day=dateInfo.day),
      Point(device="device2", timestamp=timestamp2, temperature=2, humidity=2, moisture=2, year=dateInfo.year, month=dateInfo.month, day=dateInfo.day)
    ).toDS()

    // While
    val outputDataFrame = PointsTransformation.getDataSetAsMeanOfPoint(dataSet)

    // Then
    val expectedResult = Seq(
      MeanOfPoints(device="device1", hour=1, timestampFrom=timestampFrom, timestampTo=timestampTo, meanTemperature=1.5, meanHumidity=1.5, meanMoisture=1.5, year=dateInfo.year, month=dateInfo.month, day=dateInfo.day),
      MeanOfPoints(device="device2", hour=14, timestampFrom=timestampFrom, timestampTo=timestampTo, meanTemperature=1.5, meanHumidity=1.5, meanMoisture=1.5, year=dateInfo.year, month=dateInfo.month, day=dateInfo.day),
      MeanOfPoints(device="device1", hour=23, timestampFrom=timestampFrom, timestampTo=timestampTo, meanTemperature=3, meanHumidity=3, meanMoisture=3, year=dateInfo.year, month=dateInfo.month, day=dateInfo.day)
    )
    outputDataFrame.show()
    outputDataFrame.collect().toSeq should contain theSameElementsAs expectedResult
  }
}