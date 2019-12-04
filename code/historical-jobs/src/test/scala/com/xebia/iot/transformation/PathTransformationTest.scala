package com.xebia.iot.transformation

import java.io.File
import java.nio.file.{Files, Paths}
import java.net.URI

import com.xebia.iot.utils.SparkTestUtils
import org.apache.hadoop.fs.FileSystem
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.{LocatedFileStatus, Path, RemoteIterator}
import org.scalatest.{FlatSpec, Matchers}

class PathTransformationTest extends FlatSpec with Matchers with SparkTestUtils {

  "From a directory" should "get list of objects" in {

    // Given
    val incoming: String = getClass.getResource("/incoming").toURI.toString

    // When
    val listOfObjects = DataFrameTransformation.getListOfObjects(incoming)

    // Then
    val expectedListOfObjects = Seq(incoming + "/file1.json", incoming + "/file2.json")
    listOfObjects should contain theSameElementsAs expectedListOfObjects
  }
}
