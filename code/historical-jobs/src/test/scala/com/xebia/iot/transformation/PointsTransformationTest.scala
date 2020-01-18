package com.xebia.iot.transformation

import java.sql.Timestamp

import com.xebia.iot.data.{AveragePointByDeviceAndDate, Point}
import com.xebia.iot.utils.SparkTestUtils
import org.scalatest.{FlatSpec, Matchers}

class PointsTransformationTest extends FlatSpec with Matchers with SparkTestUtils {

  it should "get an average point" in {

      // Given
      import spark.implicits._

      val points = Seq(
        Point(
          device="device1",
          timestamp=Timestamp.valueOf("2019-10-22 00:00:00"),
          temperature=10,
          humidity=20,
          moisture=30,
          historicalJobDone=true,
          day=22,
          month=10,
          year=2019
        ),
        Point(
          device="device1",
          timestamp=Timestamp.valueOf("2019-10-22 00:00:00"),
          temperature=11,
          humidity=22,
          moisture=33,
          historicalJobDone=true,
          day=22,
          month=10,
          year=2019
        ),
        Point(
          device="device2",
          timestamp=Timestamp.valueOf("2019-10-22 00:00:00"),
          temperature=10,
          humidity=20,
          moisture=30,
          historicalJobDone=true,
          day=22,
          month=10,
          year=2019
        ),
        Point(
          device="device2",
          timestamp=Timestamp.valueOf("2019-10-22 00:00:00"),
          temperature=11,
          humidity=22,
          moisture=33,
          historicalJobDone=true,
          day=22,
          month=10,
          year=2019
        )
      ).toDS()

      // When`
      val averagePointsPerDeviceAndDate = PointsTransformation.getAveragePointPerDeviceAndDate(points)

      //Then
      val expectedAveragePointsPerDeviceAndDate = Seq(
        AveragePointByDeviceAndDate(
          device="device1",
          temperature=10.5,
          humidity=21,
          moisture=31.5,
          day=22,
          month=10,
          year=2019
        ),
        AveragePointByDeviceAndDate(
          device="device2",
          temperature=10.5,
          humidity=21,
          moisture=31.5,
          day=22,
          month=10,
          year=2019
        )
      )

      averagePointsPerDeviceAndDate.collect().toSeq should contain theSameElementsAs expectedAveragePointsPerDeviceAndDate
    }
}



