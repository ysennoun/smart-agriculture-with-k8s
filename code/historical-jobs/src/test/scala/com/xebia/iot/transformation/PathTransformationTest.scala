package com.xebia.iot.transformation

import java.net.URI

import com.xebia.iot.utils.SparkTestUtils
import org.scalatest.{FlatSpec, Matchers}
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.{FileSystem, LocatedFileStatus, Path, RemoteIterator}

class PathTransformationTest extends FlatSpec with Matchers with SparkTestUtils {

  "From a directory" should "get list of objects" in {

    // Given
    val incoming: String = getClass.getResource("/incoming").toURI.toString

    // When
    val listOfObjects = PathTransformation.getListOfObjects(incoming)

    // Then
    val expectedListOfObjects = Seq(incoming + "/file1.json", incoming + "/file2.json")
    listOfObjects should contain theSameElementsAs expectedListOfObjects
  }

  it should "convert to iterator" in {

    // Given
    val hdfsPath = getClass.getResource("/incoming/file1.json").toURI.toString
    val fs = FileSystem.get(URI.create(hdfsPath), new Configuration())
    val path = new Path(hdfsPath)
    val files: RemoteIterator[LocatedFileStatus] = fs.listFiles(path, true)

    // When
    val iterator = PathTransformation.convertToScalaIterator(files)

    // Then
    val expectedIterator = Seq(hdfsPath)
    iterator.map(_.getPath.toString).toSeq should contain theSameElementsAs expectedIterator
  }
}
