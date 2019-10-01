package com.xebia.iot.transformation

import java.io.{File, PrintWriter}
import java.nio.file.{Files, Paths}
import java.net.{URI, URL}

import com.xebia.iot.utils.SparkTestUtils
import org.apache.hadoop.fs.FileSystem
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.{LocatedFileStatus, Path, RemoteIterator}
import org.scalatest.{FlatSpec, Matchers}

class DataFrameTransformationTest extends FlatSpec with Matchers with SparkTestUtils {

  "From a directory" should "get list of objects" in {

    // Given
    val incoming: String = getClass.getResource("/incoming").toURI.toString

    // When
    val listOfObjects = DataFrameTransformation.getListOfObjects(incoming)

    // Then
    val expectedListOfObjects = Seq(incoming + "/file1.json", incoming + "/file2.json")
    listOfObjects should contain theSameElementsAs expectedListOfObjects
  }

  it should "move files from  source to a destination" in {

    // Given
    val rawData = getClass.getResource("/raw-data").getPath
    val newFilePath = "new-file-" + scala.util.Random.nextInt(100000).toString
    new File(newFilePath).createNewFile()
    val fileInRawDataPath = rawData + "/" + newFilePath

    // When
    val listOfObjects = Seq(newFilePath)
    DataFrameTransformation.moveObjects(listOfObjects, rawData)

    Files.exists(Paths.get(fileInRawDataPath)) shouldBe true
  }

  it should "convert to iterator" in {

    // Given
    val hdfsPath = getClass.getResource("/incoming/file1.json").toURI.toString
    val fs = FileSystem.get(URI.create(hdfsPath), new Configuration())
    val path = new Path(hdfsPath)
    val files: RemoteIterator[LocatedFileStatus] = fs.listFiles(path, true)

    // When
    val iterator = DataFrameTransformation.convertToScalaIterator(files)

    // Then
    val expectedIterator = Seq(hdfsPath)
    iterator.map(_.getPath.toString).toSeq should contain theSameElementsAs expectedIterator
  }
}
