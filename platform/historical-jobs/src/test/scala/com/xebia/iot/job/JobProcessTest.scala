package com.xebia.iot.job

import com.xebia.iot.utils.{Logging, SparkTestUtils}
import org.scalatest.{FlatSpec, Matchers}


class JobProcessTest extends FlatSpec with Matchers with SparkTestUtils with Logging {

  it should "get most recent point" in {

    // Given
    import spark.implicits._
    val dataFrame = Seq(
      ("device1", "2019-10-22T00:00:00Z", 10, 20, 30, 2019, 20, 22),
      ("device2", "2019-10-22T00:00:01Z", 11, 21, 31, 2019, 20, 22),
      ("device3", "2019-10-22T00:00:00Z", 11, 21, 31, 2019, 20, 22)
    ).toDF("device", "timestamp", "temperature", "humidity", "moisture", "year", "month", "day")

    // When
    val mostRecent = JobProcess.getMostRecentRecord(dataFrame, "timestamp")

    //Then
    val expectedMostRecent = Seq(
      ("device2", "2019-10-22T00:00:01Z", 11, 21, 31, 2019, 20, 22)
    ).toDF("device", "timestamp", "temperature", "humidity", "moisture", "year", "month", "day")

    mostRecent.collect() should contain theSameElementsAs expectedMostRecent.collect()
  }
}
