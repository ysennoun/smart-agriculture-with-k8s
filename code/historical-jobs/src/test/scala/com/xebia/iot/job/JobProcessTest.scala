package com.xebia.iot.job

import java.sql.Timestamp

import sys.process._
import com.xebia.iot.utils.{Logging, SparkTestUtils}
import org.scalatest.{FlatSpec, Matchers}

class JobProcessTest extends FlatSpec with Matchers with SparkTestUtils with Logging {

  it should "get most recent point" in {

    // Given
    import spark.implicits._
    val dataFrame = Seq(
      ("device1", Timestamp.valueOf("2019-10-22 00:00:00"), 10, 20, 30),
      ("device2", Timestamp.valueOf("2019-10-22 00:00:01"), 11, 21, 31)
    ).toDF("device", "timestamp", "temperature", "humidity", "moisture")

    // When
    val mostRecent = JobProcess.getMostRecentRecord(dataFrame, "timestamp")

    //Then
    val expectedMostRecent = Seq(
      ("device2", Timestamp.valueOf("2019-10-22 00:00:01"), 11, 21, 31)
    ).toDF("device", "timestamp", "temperature", "humidity", "moisture")

    mostRecent.collect() should contain theSameElementsAs expectedMostRecent.collect()
  }

  it should "get point" in {

    // Given
    import spark.implicits._

    sparkConf.set("es.index.auto.create", "true")
    sparkConf.set("es.nodes", "localhost")
    sparkConf.set("es.port", "9200")
    val esAliasForHistoricalJobs="historical-jobs"

    val response = s"curl -X PUT http://localhost:9200/$esAliasForHistoricalJobs".!!
    logger.info(s"Response from curl: $response")

    val result = JobProcess.getStartTimestamp(esAliasForHistoricalJobs)
    logger.info(s"ee$result")
  }
}
