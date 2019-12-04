package com.xebia.iot.transformation

import java.io.File
import java.nio.file.{Files, Paths}
import java.net.URI

import com.xebia.iot.utils.SparkTestUtils
import org.apache.hadoop.fs.FileSystem
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.{LocatedFileStatus, Path, RemoteIterator}
import org.scalatest.{FlatSpec, Matchers}

class DataFrameTransformationTest extends FlatSpec with Matchers with SparkTestUtils {

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

  it should "get a limited number of data as json string" in {

    // Given
    /**
     * Data store in file resources/prepared-data/data.parquet contains the following lines
     * +------+---+
     * |  name|age|
     * +------+---+
     * |  Andy| 32|
     * | Marie| 24|
     * | Nadia| 21|
     * |   Ana| 24|
     * |Laurie| 24|
     * |Mariam| 24|
     * |Hakima| 24|
     * +------+---+
     **/
    val preparedData = getClass.getResource("/prepared-data").getPath
    columnNameToOrder = "name"

    // When
    val limitedNumberOfDataAsJsonString = DataFrameTransformation.getLimitedNumberOfDataAsJsonString(preparedData, columnNameToOrder)

    //Then
    expectedLimitedNumberOfDataAsJsonString = "[{"name":"Ana","age":24},{"name":"Andy","age":32},{"name":"Hakima","age":24},{"name":"Laurie","age":24},{"name":"Mariam","age":24},{"name":"Marie","age":24},{"name":"Nadia","age":21}][{"name":"Ana","age":24},{"name":"Andy","age":32},{"name":"Hakima","age":24},{"name":"Laurie","age":24},{"name":"Mariam","age":24},{"name":"Marie","age":24},{"name":"Nadia","age":21}]"

    limitedNumberOfDataAsJsonString shouldBe expectedLimitedNumberOfDataAsJsonString
  }
}
