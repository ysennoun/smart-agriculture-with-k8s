package com.xebia.iot.job

import com.xebia.iot.data.{DataPath, MeanOfPoints, Point}
import com.xebia.iot.exception.JobException.WrongJobException
import com.xebia.iot.transformation.DataFrameTransformation.{getDataFrameFromJson, getDataFrameFromParquet, getListOfObjects, moveObjects, saveDataFrame, getLimitedNumberOfDataAsJsonString}
import com.xebia.iot.transformation.PathTransformation.getListOfObjects
import org.apache.spark.SparkContext
import org.apache.spark.sql.{Dataset, SparkSession}

object RunJob {

  def runner(job: String, path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    job match {
      case "JsonToParquet" => runJsonToParquet(path)
      case "LimitedNumberOfDataSelected" => runLimitedNumberOfDataSelected(path)
      case _ =>
        val message = s"Job $job is not recognized, failed to run spark job!"
        println(message)
        throw WrongJobException(message)
    }
  }

  def runJsonToParquet(path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    val listOfObjects = getListOfObjects(path.incomingDataPath)
    val dataFrame = getDataFrameFromJson(listOfObjects)
    val dataSetAsPoint: Dataset[Point] = getDatSetAsPoint(dataFrame)
    saveDataFrame(dataSetAsPoint.toDF(), path.preparedDataPath)
    moveObjects(listOfObjects, path.rawDataPath)
  }

  def runLimitedNumberOfDataSelected(path: DataPath)(implicit spark: SparkSession, sc: SparkContext) ={
    val limitedNumberOfDataAsJsonString = getLimitedNumberOfDataAsJsonString(path.preparedDataPath, "timestamp")
    println("LimitedNumberOfDataSelected: " + limitedNumberOfDataAsJsonString)
  }
}

https://spark.apache.org/docs/latest/sql-data-sources-parquet.html
https://stackoverflow.com/questions/21510360/how-to-get-the-output-from-jar-execution-in-python-codes
