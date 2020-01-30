package com.xebia.iot.job

import java.sql.Timestamp

import com.xebia.iot.data.{DataPath, HistoricalJob}
import com.xebia.iot.exception.JobException.WrongJobException
import com.xebia.iot.transformation.DataFrameTransformation.{getDataFrameFromElasticsearch, getDataFrameFromParquet, saveDataFrameInElasticsearch, saveDataFrameInObjectStore}
import com.xebia.iot.transformation.PointsTransformation.{getAveragePointPerDeviceAndDate, getDatSetAsPoint}
import org.apache.spark.SparkContext
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

object RunJob {

  val task = "historical"
  val filterForLastJob = s"?q=task:$task&size=1&sort=timestamp:desc"

  def runner(job: String, path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    job match {
      case "EsToParquet" => runEsToParquet(path)
      case "AveragePerDeviceAndDate" => runAveragePerDeviceAndDate(path)
      case _ =>
        val message = s"Job $job is not recognized, failed to run spark job!"
        println(message)
        throw WrongJobException(message)
    }
  }

  def runEsToParquet(path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    val dataFrameForLastJob = getDataFrameFromElasticsearch(path.esAliasForHistoricalJobs, filterForLastJob)
    val dataSetAsPointForLastJob = getDatSetAsPoint(dataFrameForLastJob)
    val fromTimestamp = dataSetAsPointForLastJob.head().timestamp
    val filter = s"?q=*:*&facet.range=timestamp&facet=true&facet.range.start=$fromTimestamp"
    val dataFrame = getDataFrameFromElasticsearch(path.esAliasForIncomingData, filter)
    val dataSetAsPoint = getDatSetAsPoint(dataFrame)
    saveDataFrameInObjectStore(dataSetAsPoint.toDF(), path.s3PreparedDataPath)

    import spark.implicits._
    val timestamp = dataSetAsPoint.map(_.timestamp).agg(max("timestamp")).head().getAs[Timestamp](0)
    val newDataFrame = Seq(HistoricalJob(task, timestamp)).toDF()
    saveDataFrameInElasticsearch(newDataFrame, path.esAliasForHistoricalJobs)
  }

  def runAveragePerDeviceAndDate(path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    val dataFrame = getDataFrameFromParquet(path.s3PreparedDataPath)
    val dataSetAsPoint = getDatSetAsPoint(dataFrame)
    val dataSetAsAveragePointPerDeviceAndDate = getAveragePointPerDeviceAndDate(dataSetAsPoint)
    saveDataFrameInElasticsearch(dataSetAsAveragePointPerDeviceAndDate.toDF(), path.esAliasForAveragePerDeviceAndDate)
  }
}
