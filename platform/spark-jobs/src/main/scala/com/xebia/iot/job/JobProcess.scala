package com.xebia.iot.job

import java.sql.Timestamp
import java.time.format.DateTimeFormatter
import java.time.LocalDateTime

import org.apache.spark.SparkContext
import org.apache.spark.sql.expressions.Window
import org.apache.spark.sql.functions.{col, dayofmonth, month, rank, year}
import org.apache.spark.sql.{DataFrame, SparkSession}
import com.xebia.iot.utils.Logging
import com.xebia.iot.exception.JobException.NoRecordsFoundDefinedException
import com.xebia.iot.transformation.DataFrameTransformation.getDataFrameFromElasticsearch


object JobProcess extends Logging {

  def getStartTimestamp(esAliasForHistoricalJobs: String)
                       (implicit spark: SparkSession, sc: SparkContext): Timestamp ={
    val filterForLastJob =
      """
        |{
        |    "query" : {
        |        "match_all": {}
        |    },
        |    "size": 1,
        |    "sort" : [
        |        { "timestamp" : {"order" : "desc"}}
        |    ]
        |}
        |""".stripMargin
    logger.info(s"Get Start Timestamp, filter=$filterForLastJob")
    val dataFrameForLastJob = getDataFrameFromElasticsearch(esAliasForHistoricalJobs, filterForLastJob)
    if (dataFrameForLastJob.isEmpty)
      Timestamp.valueOf(LocalDateTime.now.toLocalDate.atStartOfDay) // Return Timestamp at midnight
    else
      dataFrameForLastJob.select("timestamp").first().get(0).asInstanceOf[Timestamp]
  }

  def getRecentRecords(esAliasForIncomingData: String, timestamp: Timestamp)
                      (implicit spark: SparkSession, sc: SparkContext): Either[NoRecordsFoundDefinedException, DataFrame] ={

    val timestampAsString = DateTimeFormatter.ISO_LOCAL_DATE_TIME.format(timestamp.toLocalDateTime)
    val filterRecentRecords =
      s"""
        |{
        |    "query" : {
        |       "range" : {
        |            "timestamp" : {
        |                "time_zone": "+00:00",
        |                "gt" : "$timestampAsString",
        |                "lte": "now"
        |            }
        |        }
        |    }
        |}
        |""".stripMargin
    logger.info(s"Get Recent Records, filter=$filterRecentRecords")
    val dataFrame = getDataFrameFromElasticsearch(esAliasForIncomingData, filterRecentRecords)
    if (dataFrame.isEmpty) Left(NoRecordsFoundDefinedException("No new records found"))
    else Right(dataFrame
      .withColumn("year", year(col("timestamp")))
      .withColumn("month", month(col("timestamp")))
      .withColumn("day", dayofmonth(col("timestamp")))
    )
  }

  def getMostRecentRecord(dataFrame: DataFrame, orderByColumnName: String): DataFrame = {
    logger.info("Get Most Recent Record")
    val windowSpec = Window
      .orderBy(col(orderByColumnName).desc)

    val rankColumnName = "rank_column"

    dataFrame
      .withColumn(rankColumnName, rank().over(windowSpec))
      .filter(col(rankColumnName) === 1)
      .drop(rankColumnName)
  }
}
