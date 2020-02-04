package com.xebia.iot

import com.xebia.iot.data.DataPath
import com.xebia.iot.exception.JobException.WrongNumberOfArgumentsException
import com.xebia.iot.transformation.DataFrameTransformation.{getDataFrameFromParquet, saveDataFrameInElasticsearch}
import com.xebia.iot.transformation.PointsTransformation.{getAveragePointPerDeviceAndDate, getDatSetAsPoint}
import org.apache.spark.SparkContext
import org.apache.spark.sql.SparkSession

object MainEsToParquet {

  def main(args: Array[String]): Unit = {
    val dataPath = getDataPath(args)
    implicit val spark = SparkSession.builder.getOrCreate()
    implicit val sc = spark.sparkContext

    runAveragePerDeviceAndDate(dataPath)
    spark.stop()
  }

  def getDataPath(args: Array[String]): DataPath={
    if (args.length != 4){
      val errorMessage = "Wrong number of arguments, it should be 5"
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

  def runAveragePerDeviceAndDate(path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    val dataFrame = getDataFrameFromParquet(path.s3PreparedDataPath)
    val dataSetAsPoint = getDatSetAsPoint(dataFrame)
    val dataSetAsAveragePointPerDeviceAndDate = getAveragePointPerDeviceAndDate(dataSetAsPoint)
    saveDataFrameInElasticsearch(dataSetAsAveragePointPerDeviceAndDate.toDF(), path.esAliasForAveragePerDeviceAndDate)
  }
}