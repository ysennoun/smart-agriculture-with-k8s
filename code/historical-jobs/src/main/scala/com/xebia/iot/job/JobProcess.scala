package com.xebia.iot.job

import java.sql.Timestamp

import com.xebia.iot.data.Point
import org.apache.spark.SparkContext
import org.apache.spark.sql.expressions.Window
import org.apache.spark.sql.functions.{col, rank}
import org.apache.spark.sql.{DataFrame, Row, SparkSession}
import com.xebia.iot.utils.Logging
import com.xebia.iot.exception.JobException.{NoRecordTimestampColumnDefinedException, NoRecordsFoundDefinedException}
import com.xebia.iot.transformation.DataFrameTransformation.getDataFrameFromElasticsearch


object JobProcess extends Logging {

  def getStartTimestamp(esAliasForHistoricalJobs: String)
                       (implicit spark: SparkSession, sc: SparkContext): Either[NoRecordTimestampColumnDefinedException, Timestamp] ={
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
    logger.debug(s"Get Start Timestamp, filter=$filterForLastJob")
    val dataFrameForLastJob = getDataFrameFromElasticsearch(esAliasForHistoricalJobs, filterForLastJob)
    if(dataFrameForLastJob.isEmpty)
      Left(NoRecordTimestampColumnDefinedException("No record found for last job"))
    else{
      Right(dataFrameForLastJob.first().asInstanceOf[Point].timestamp)
    }
  }

  def getRecentRecords(esAliasForIncomingData: String, timestamp: Timestamp)
                      (implicit spark: SparkSession, sc: SparkContext): Either[NoRecordsFoundDefinedException, DataFrame] ={
    val filterRecentRecords =
      s"""
        |{
        |    "query" : {
        |       "range" : {
        |            "timestamp" : {
        |                "gte" : "$timestamp"
        |            }
        |        }
        |    }
        |}
        |""".stripMargin
    logger.debug(s"Get Recent Records, filter=$filterRecentRecords")
    val dataFrame = getDataFrameFromElasticsearch(esAliasForIncomingData, filterRecentRecords)
    if (dataFrame.isEmpty) Left(NoRecordsFoundDefinedException("No new records found"))
    else Right(dataFrame)
  }

  def getMostRecentRecord(dataFrame: DataFrame, orderByColumnName: String): DataFrame = {
    logger.debug("Get Most Recent Record")
    val windowSpec = Window
      .orderBy(col(orderByColumnName).desc)

    val rankColumnName = "rank_column"

    dataFrame
      .withColumn(rankColumnName, rank().over(windowSpec))
      .filter(col(rankColumnName) === 1)
      .drop(rankColumnName)
  }
}
