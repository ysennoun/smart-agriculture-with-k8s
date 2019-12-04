package com.xebia.iot.transformation

import java.net.URI

import com.xebia.iot.utils.CustomFile.getFilePath
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.{FileSystem, LocatedFileStatus, Path, RemoteIterator}
import org.apache.spark.SparkContext
import org.apache.spark.sql.functions._
import org.apache.spark.sql.{DataFrame, SaveMode, SparkSession}

object DataFrameTransformation {

  val LIMIT_NUMBER_ELEMENTS = 20

  def getDataFrameFromJson(jsonPaths: Seq[String])(implicit spark: SparkSession): DataFrame ={
    spark.read.json(jsonPaths.mkString(","))
  }

  def getDataFrameFromParquet(parquetPath: String)(implicit spark: SparkSession): DataFrame={
    spark.read.parquet(parquetPath)
  }

  def saveDataFrame(dataFrame: DataFrame, outputParquetPath: String)(implicit spark: SparkSession)={
    dataFrame
      .coalesce(10)
      .write
      .mode(SaveMode.Append)
      .partitionBy("year", "month", "day")
      .parquet(outputParquetPath)
  }

  def moveObjects(listOfObjects: Seq[String], outputParquetPath: String)(implicit spark: SparkSession, sc: SparkContext) ={
    val configuration: Configuration = sc.hadoopConfiguration
    listOfObjects.foreach(objectPath => {
      val newObjectPath = getFilePath(objectPath, outputParquetPath)
      spark.sparkContext.textFile(objectPath).saveAsObjectFile(newObjectPath)
      val fileSystem = FileSystem.get(URI.create(objectPath), configuration)
      fileSystem.delete(new Path(objectPath), true)
    })
  }

  def getLimitedNumberOfDataAsJsonString(inputParquetPath: String, columnNameToOrder: String)(implicit spark: SparkSession): String = {
    val parquetFileDF = spark.read.parquet(inputParquetPath)
    val limitedNumberOfDataAsJson = parquetFileDF.orderBy(asc(columnNameToOrder)).toJSON.take(LIMIT_NUMBER_ELEMENTS)
    val limitedNumberOfDataAsJsonString = "[" + limitedNumberOfDataAsJson.mkString(",") + "]"
    limitedNumberOfDataAsJsonString
  }
}
