package com.xebia.iot.job

import com.xebia.iot.data.{DataPath, MeanOfPoints, Point}
import com.xebia.iot.exception.JobException.WrongJobException
import com.xebia.iot.transformation.DataFrameTransformation.{getDataFrameFromJson, getDataFrameFromParquet, getListOfObjects, moveObjects, saveDataFrame, getLimitedNumberOfDataOverDate}
import com.xebia.iot.transformation.PathTransformation.getListOfObjects
import org.apache.spark.SparkContext
import org.apache.spark.sql.{Dataset, SparkSession}

object RunJob {

  def runner(job: String, path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    job match {
      case "JsonToParquet" => runJsonToParquet(path)
      case "SelectPoints" => runSelectPoints(path)
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

  def runSelectPoints(path: DataPath)(implicit spark: SparkSession, sc: SparkContext): String ={
    getLimitedNumberOfDataOverDate(path.preparedDataPath, "timestamp")
  }
}
