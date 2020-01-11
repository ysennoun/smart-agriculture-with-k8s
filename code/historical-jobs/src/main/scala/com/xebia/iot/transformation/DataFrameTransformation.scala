package com.xebia.iot.transformation

import org.apache.spark.sql.functions._
import org.apache.spark.sql.{DataFrame, SaveMode, SparkSession}
import org.elasticsearch.spark.sql._

object DataFrameTransformation {

  val LIMIT_NUMBER_ELEMENTS = 20

  def getDataFrameFromElasticsearch(index: String, filter: String)(implicit spark: SparkSession): DataFrame ={
    spark.sqlContext.esDF(index, filter)
  }

  def getDataFrameFromParquet(parquetPath: String)(implicit spark: SparkSession): DataFrame={
    spark.read.parquet(parquetPath)
  }

  def saveDataFrameInObjectStore(dataFrame: DataFrame, outputParquetPath: String)(implicit spark: SparkSession)={
    dataFrame
      .coalesce(10)
      .write
      .mode(SaveMode.Append)
      .partitionBy("year", "month", "day")
      .parquet(outputParquetPath)
  }

  def saveDataFrameInElasticsearch(dataFrame: DataFrame, index: String)(implicit spark: SparkSession)={
    dataFrame.saveToEs(index)
  }

  def updateColumnValueInDataFrame(dataFrame: DataFrame, columnName: String, columnValue: Any)(implicit spark: SparkSession) ={
    dataFrame.withColumn(columnName, lit(columnValue))
  }

  def getLimitedNumberOfDataAsJsonString(inputParquetPath: String, columnNameToOrder: String)(implicit spark: SparkSession): String = {
    val parquetFileDF = spark.read.parquet(inputParquetPath)
    val limitedNumberOfDataAsJson = parquetFileDF.orderBy(asc(columnNameToOrder)).toJSON.take(LIMIT_NUMBER_ELEMENTS)
    val limitedNumberOfDataAsJsonString = "[" + limitedNumberOfDataAsJson.mkString(",") + "]"
    limitedNumberOfDataAsJsonString
  }
}
