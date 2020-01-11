package com.xebia.iot.job

import com.xebia.iot.data.{DataPath, Point}
import com.xebia.iot.exception.JobException.WrongJobException
import com.xebia.iot.transformation.DataFrameTransformation.{getDataFrameFromElasticsearch, updateColumnValueInDataFrame, saveDataFrameInObjectStore, saveDataFrameInElasticsearch}
import com.xebia.iot.transformation.PointsTransformation.getDatSetAsPoint
import org.apache.spark.SparkContext
import org.apache.spark.sql.{Dataset, SparkSession}

object RunJob {

  def runner(job: String, path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    job match {
      case "JsonToParquet" => runJsonToParquet(path)
      case "LimitedNumberOfDataSelected" => ""
      case _ =>
        val message = s"Job $job is not recognized, failed to run spark job!"
        println(message)
        throw WrongJobException(message)
    }
  }

  def runJsonToParquet(path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    val dataFrame = getDataFrameFromElasticsearch(path.incomingIndex, "?q=historicalJobDone:false")
    val dataSetAsPoint: Dataset[Point] = getDatSetAsPoint(dataFrame)
    saveDataFrameInObjectStore(dataSetAsPoint.toDF(), path.preparedDataPath)
    val updatedDataFrame = updateColumnValueInDataFrame(dataFrame, "historicalJobDone", true)
    saveDataFrameInElasticsearch(updatedDataFrame, path.incomingIndex)
  }
}

//https://spark.apache.org/docs/latest/sql-data-sources-parquet.html
//https://stackoverflow.com/questions/21510360/how-to-get-the-output-from-jar-execution-in-python-codes
