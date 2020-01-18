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

    spark.conf.set("es.index.auto.create", "true")
    sc.hadoopConfiguration.set("fs.s3a.endpoint", "http://localhost:9000")
    RunJob.runner(arguments.job, arguments.path)
    spark.stop()
  }

  def getArguments(args: Array[String]): Arguments={
    if (args.length != 3){
      val errorMessage = "Wrong number of arguments, it should be 3"
      println(errorMessage)
      throw WrongNumberOfArgumentsException(errorMessage)
    }
    Arguments(
      path=DataPath(
        incomingIndex=args.apply(0),
        preparedDataPath=args.apply(1)
      ),
      job=args.apply(2)
    )
  }
}
