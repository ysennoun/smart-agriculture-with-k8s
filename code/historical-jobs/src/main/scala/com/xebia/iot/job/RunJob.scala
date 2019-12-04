package com.xebia.iot.job

import com.xebia.iot.data.{DataPath, MeanOfPoints, Point}
import com.xebia.iot.exception.JobException.WrongJobException
import com.xebia.iot.transformation.DataFrameTransformation.{getDataFrameFromJson, getDataFrameFromParquet, getListOfObjects, moveObjects, saveDataFrame}
import com.xebia.iot.transformation.PointsTransformation.{getDatSetAsPoint, getDataSetAsMeanOfPoint}
import org.apache.spark.SparkContext
import org.apache.spark.sql.{Dataset, SparkSession}

object RunJob {

  def runJob(job: String, path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    job match {
      case "MeanOfPointsJob" => runMeanOfPointsJob(path)
      case "PointJob" => runPointJob(path)
      case _ =>
        val message = s"Job $job is not recognized, failed to run spark job!"
        println(message)
        throw WrongJobException(message)
    }
  }

  def runMeanOfPointsJob(path: DataPath)(implicit spark: SparkSession)={
    import spark.implicits._
    val dataFrame = getDataFrameFromParquet(path.incomingDataPath)
    val dataSetAsPoint: Dataset[Point] = dataFrame.as[Point]
    val dataSetAsMeanOfPoint: Dataset[MeanOfPoints] = getDataSetAsMeanOfPoint(dataSetAsPoint)
    saveDataFrame(dataSetAsMeanOfPoint.toDF(), path.preparedDataPath)
  }

  def runPointJob(path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    val listOfObjects = getListOfObjects(path.incomingDataPath)
    val dataFrame = getDataFrameFromJson(listOfObjects)
    val dataSetAsPoint: Dataset[Point] = getDatSetAsPoint(dataFrame)
    saveDataFrame(dataSetAsPoint.toDF(), path.preparedDataPath)
    moveObjects(listOfObjects, path.rawDataPath)
  }
}

https://spark.apache.org/docs/latest/sql-data-sources-parquet.html
https://stackoverflow.com/questions/21510360/how-to-get-the-output-from-jar-execution-in-python-codes
