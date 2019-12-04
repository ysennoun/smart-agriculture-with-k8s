package com.xebia.iot.transformation

import java.net.URI

import com.xebia.iot.utils.CustomFile.getFilePath
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.{FileSystem, LocatedFileStatus, Path, RemoteIterator}
import org.apache.spark.SparkContext
import org.apache.spark.sql.functions._
import org.apache.spark.sql.{DataFrame, SaveMode, SparkSession}

object PathTransformation {

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

