package com.xebia.iot.transformation

import java.sql.Timestamp

import com.xebia.iot.data.Point
import com.xebia.iot.utils.SparkTestUtils
import org.scalatest.{FlatSpec, Matchers}

class PointsTransformationTest extends FlatSpec with Matchers with SparkTestUtils {

  it should "get an average point" in {

    // Given
    import spark.implicits._
    val pointsAsDataFrame = Seq(
      ("device1", Timestamp.valueOf("2019-10-22 00:00:00"), 10, 20, 30),
      ("device2", Timestamp.valueOf("2019-10-22 00:00:00"), 11, 21, 31)
    ).toDF("device", "timestamp", "temperature", "humidity", "moisture")

    // When`
    val pointsAsDataSet = PointsTransformation.getDatSetAsPoint(pointsAsDataFrame)

    //Then
    val expectedPoints = Seq(
      Point(
        device="device1",
        timestamp=Timestamp.valueOf("2019-10-22 00:00:00"),
        temperature=10,
        humidity=20,
        moisture=30,
        day=22,
        month=10,
        year=2019
      ),
      Point(
        device="device2",
        timestamp=Timestamp.valueOf("2019-10-22 00:00:00"),
        temperature=11,
        humidity=21,
        moisture=31,
        day=22,
        month=10,
        year=2019
      )
    )

    pointsAsDataSet.collect().toSeq should contain theSameElementsAs expectedPoints
  }
}

