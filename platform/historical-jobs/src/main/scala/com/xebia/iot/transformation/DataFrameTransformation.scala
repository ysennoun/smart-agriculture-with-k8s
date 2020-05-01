package com.xebia.iot.transformation

import com.xebia.iot.utils.Logging
import org.apache.spark.sql.{DataFrame, SaveMode, SparkSession}
import org.elasticsearch.spark.sql._


object DataFrameTransformation  extends Logging {

  def getDataFrameFromElasticsearch(index: String, filter: String)(implicit spark: SparkSession): DataFrame ={
    logger.debug(s"Get DataFrame From Elasticsearch, index=$index and filter=$filter")
    spark.sqlContext.esDF(index, filter)
  }

  def getDataFrameFromParquet(parquetPath: String)(implicit spark: SparkSession): DataFrame={
    logger.debug(s"Get DataFrame From Parquet, path=$parquetPath")
    spark.read.parquet(parquetPath)
  }

  def saveDataFrameInObjectStore(dataFrame: DataFrame, outputParquetPath: String)(implicit spark: SparkSession)={
    logger.debug(s"Save DataFrame in Object Store, path=$outputParquetPath")

    dataFrame
      .coalesce(3)
      .write
      .mode(SaveMode.Append)
      .partitionBy("year", "month", "day")
      .parquet(outputParquetPath)
  }

  def saveDataFrameInElasticsearch(dataFrame: DataFrame, index: String)(implicit spark: SparkSession)={
    logger.debug(s"Save DataFrame in Elasticsearch, index=$index")
    dataFrame.saveToEs(index)
  }
}
