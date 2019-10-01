package com.xebia.iot.transformation

import java.net.URI

import com.xebia.iot.utils.CustomFile.getFilePath
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.{FileSystem, LocatedFileStatus, Path, RemoteIterator}
import org.apache.spark.SparkContext
import org.apache.spark.sql.{DataFrame, SaveMode, SparkSession}

object DataFrameTransformation {

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

  def moveObjects(listOfObjects: Seq[String], rawDataPath: String)(implicit spark: SparkSession, sc: SparkContext) ={
    val configuration: Configuration = sc.hadoopConfiguration
    listOfObjects.foreach(objectPath => {
      val newObjectPath = getFilePath(objectPath, rawDataPath)
      spark.sparkContext.textFile(objectPath).saveAsObjectFile(newObjectPath)
      val fileSystem = FileSystem.get(URI.create(objectPath), configuration)
      fileSystem.delete(new Path(objectPath), true)
    })
  }

  def getListOfObjects(path: String)(implicit sc: SparkContext): Seq[String]={
    val configuration: Configuration = sc.hadoopConfiguration
    val fileSystem = FileSystem.get(URI.create(path), configuration) //new Configuration())
    val it: RemoteIterator[LocatedFileStatus] = fileSystem.listFiles(new Path(path), true)
    val iterator: Iterator[LocatedFileStatus] = convertToScalaIterator(it)
    iterator.map(_.getPath.toString).toSeq
  }

  def convertToScalaIterator[T](underlying: RemoteIterator[T]): Iterator[T] = {
    case class wrapper(underlying: RemoteIterator[T]) extends Iterator[T] {
      override def hasNext = underlying.hasNext

      override def next = underlying.next
    }
    wrapper(underlying)
  }
}

