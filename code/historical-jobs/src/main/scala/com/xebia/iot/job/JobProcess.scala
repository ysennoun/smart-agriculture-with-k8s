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
    logger.debug("Get Start Timestamp")
    val filterForLastJob = "?q=*:*&size=1&sort=timestamp:desc"
    val dataFrameForLastJob = getDataFrameFromElasticsearch(esAliasForHistoricalJobs, filterForLastJob)
    val rowsForLastJob: Array[Row] = dataFrameForLastJob.head(1)
    if(rowsForLastJob.isEmpty)
      Left(NoRecordTimestampColumnDefinedException("No record found for last job"))
    else{
      Right(rowsForLastJob.head.asInstanceOf[Point].timestamp)
    }
  }

  def getRecentRecords(esAliasForIncomingData: String, timestamp: Timestamp)
                      (implicit spark: SparkSession, sc: SparkContext): Either[NoRecordsFoundDefinedException, DataFrame] ={
    logger.debug("Get Recent Records")
    val filter = s"?q=*:*&facet.range=timestamp&facet=true&facet.range.start=$timestamp"
    val dataFrame = getDataFrameFromElasticsearch(esAliasForIncomingData, filter)
    if (dataFrame.head(1).isEmpty) Left(NoRecordsFoundDefinedException("No new records found"))
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
