package com.xebia.iot

import com.xebia.iot.utils.Logging
import com.xebia.iot.data.DataPath
import com.xebia.iot.exception.JobException.WrongNumberOfArgumentsException
import com.xebia.iot.job.JobProcess
import com.xebia.iot.transformation.DataFrameTransformation.{saveDataFrameInElasticsearch, saveDataFrameInObjectStore}
import org.apache.spark.SparkContext
import org.apache.spark.sql.SparkSession


object MainEsToParquet extends Logging{

  def main(args: Array[String]): Unit = {
    val dataPath = getDataPath(args)
    implicit val spark = SparkSession.builder.getOrCreate()
    implicit val sc = spark.sparkContext

    runEsToParquet(dataPath)
    spark.stop()
  }

  def getDataPath(args: Array[String]): DataPath={
    logger.debug(s"Get Data Path, args=$args")
    if (args.length != 3){
      val errorMessage = "Wrong number of arguments, it should be 3"
      logger.error(errorMessage)
      throw WrongNumberOfArgumentsException(errorMessage)
    }
    DataPath(
      esAliasForIncomingData=args.apply(0),
      esAliasForHistoricalJobs=args.apply(1),
      s3PreparedDataPath=args.apply(2)
    )
  }

  def runEsToParquet(path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    logger.debug("Run ESToParquet")
    val startTimestamp = JobProcess.getStartTimestamp(path.esAliasForHistoricalJobs)
    logger.info(s"startTimestamp = $startTimestamp")
    val recentRecordsToEvaluate = JobProcess.getRecentRecords(path.esAliasForIncomingData, startTimestamp)
    recentRecordsToEvaluate match {
      case Right(recentRecords) =>
        saveDataFrameInObjectStore(recentRecords, path.s3PreparedDataPath)
        val mostRecentRecord = JobProcess.getMostRecentRecord(recentRecords, "timestamp")
        saveDataFrameInElasticsearch(mostRecentRecord, path.esAliasForHistoricalJobs)
      case Left(exception) =>
        logger.info(exception.getMessage)
    }
  }
}