package com.xebia.iot

import java.sql.Timestamp

import com.xebia.iot.data.{DataPath, HistoricalJob}
import com.xebia.iot.exception.JobException.WrongNumberOfArgumentsException
import com.xebia.iot.transformation.DataFrameTransformation.{getDataFrameFromElasticsearch, saveDataFrameInElasticsearch, saveDataFrameInObjectStore}
import com.xebia.iot.transformation.PointsTransformation.getDatSetAsPoint
import org.apache.spark.SparkContext
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions.max

object MainAveragePointPerDeviceAndDate {

  val task = "historical"
  val filterForLastJob = s"?q=task:$task&size=1&sort=timestamp:desc"

  def main(args: Array[String]): Unit = {
    val dataPath = getDataPath(args)
    implicit val spark = SparkSession.builder.getOrCreate()
    implicit val sc = spark.sparkContext

    runEsToParquet(dataPath)
    spark.stop()
  }

  def getDataPath(args: Array[String]): DataPath={
    if (args.length != 4){
      val errorMessage = "Wrong number of arguments, it should be 4"
      println(errorMessage)
      throw WrongNumberOfArgumentsException(errorMessage)
    }
    DataPath(
      esAliasForIncomingData=args.apply(0),
      esAliasForHistoricalJobs=args.apply(1),
      esAliasForAveragePerDeviceAndDate=args.apply(2),
      s3PreparedDataPath=args.apply(3)
    )
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
}