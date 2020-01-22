package com.xebia.iot.job

import com.xebia.iot.data.{DataPath, Point}
import com.xebia.iot.exception.JobException.WrongJobException
import com.xebia.iot.transformation.DataFrameTransformation.{getDataFrameFromElasticsearch, getDataFrameFromParquet, insertColumnInDataFrame, saveDataFrameInObjectStore, saveDataFrameInElasticsearch}
import com.xebia.iot.transformation.PointsTransformation.getDatSetAsPoint
import org.apache.spark.SparkContext
import org.apache.spark.sql.{Dataset, SparkSession}

object RunJob {

  def runner(job: String, path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    job match {
      case "EsToParquet" => runEsToParquet(path)
      case "AveragePerDeviceAndDate" => runAveragePerDeviceAndDate(path)
      case _ =>
        val message = s"Job $job is not recognized, failed to run spark job!"
        println(message)
        throw WrongJobException(message)
    }
  }

  def runEsToParquet(path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    val dataFrame = getDataFrameFromElasticsearch(path.incomingAlias, "?q=!(_exists_:\"historicalJobDone\")")
    //?q=_type:sms_cockpit_metrics&size=1&sort=metric_year:desc
    //https://kubernetes.io/fr/docs/concepts/services-networking/dns-pod-service/
    //gitlab on_failure https://gitlab.com/gitlab-org/gitlab-foss/issues/37567
    val dataSetAsPoint: Dataset[Point] = getDatSetAsPoint(dataFrame)
    saveDataFrameInObjectStore(dataSetAsPoint.toDF(), path.preparedDataPath)
    val newDataFrame = insertColumnInDataFrame(dataFrame, "historicalJobDone", true)
    saveDataFrameInElasticsearch(newDataFrame, path.incomingAlias)
  }

  def runAveragePerDeviceAndDate(path: DataPath)(implicit spark: SparkSession, sc: SparkContext)={
    val dataFrame = getDataFrameFromParquet(path.incomingAlias)
    val dataSetAsPoint: Dataset[Point] = getDatSetAsPoint(dataFrame)
    saveDataFrameInObjectStore(dataSetAsPoint.toDF(), path.preparedDataPath)
    val newDataFrame = insertColumnInDataFrame(dataFrame, "historicalJobDone", true)
    saveDataFrameInElasticsearch(newDataFrame, path.incomingAlias)
  }
}
