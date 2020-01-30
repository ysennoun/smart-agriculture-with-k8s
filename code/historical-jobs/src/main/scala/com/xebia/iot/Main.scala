package com.xebia.iot

import com.xebia.iot.data.DataPath
import com.xebia.iot.exception.JobException.WrongNumberOfArgumentsException
import com.xebia.iot.job.RunJob
import org.apache.spark.sql.SparkSession

object Main {

  case class Arguments(path: DataPath, job: String)

  def main(args: Array[String]): Unit = {
    val arguments = getArguments(args)
    implicit val spark = SparkSession.builder.appName("Simple Application").getOrCreate()
    implicit val sc = spark.sparkContext

    RunJob.runner(arguments.job, arguments.path)
    spark.stop()
  }

  def getArguments(args: Array[String]): Arguments={
    if (args.length != 5){
      val errorMessage = "Wrong number of arguments, it should be 5"
      println(errorMessage)
      throw WrongNumberOfArgumentsException(errorMessage)
    }
    Arguments(
      path=DataPath(
        esAliasForIncomingData=args.apply(0),
        esAliasForHistoricalJobs=args.apply(1),
        esAliasForAveragePerDeviceAndDate=args.apply(2),
        s3PreparedDataPath=args.apply(3)
      ),
      job=args.apply(4)
    )
  }
}