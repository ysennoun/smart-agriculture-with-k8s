package com.xebia.iot.job

import com.xebia.iot.data.DataPath
import com.xebia.iot.exception.JobException.WrongNumberOfArgumentsException
import org.apache.spark.sql.SparkSession

object Main {

  case class Arguments(path: DataPath, job: String)

  def main(args: Array[String]): Unit = {
    val arguments = getArguments(args)
    implicit val spark = SparkSession.builder.appName("Simple Application").getOrCreate()
    implicit val sc = spark.sparkContext
      
    sc.hadoopConfiguration.set("fs.s3a.endpoint", "http://localhost:9000")
    RunJob.runner(arguments.job, arguments.path)
    spark.stop()
  }

  def getArguments(args: Array[String]): Arguments={
    if (args.length != 4){
      val errorMessage = "Wrong number of arguments, it should be 4"
      println(errorMessage)
      throw WrongNumberOfArgumentsException(errorMessage)
    }
    Arguments(
      path=DataPath(
        incomingDataPath=args.apply(0),
        rawDataPath=args.apply(1),
        preparedDataPath=args.apply(2)
      ),
      job=args.apply(3)
    )
  }
}
