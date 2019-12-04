package com.xebia.iot.transformation

import java.io.File
import java.nio.file.{Files, Paths}
import com.xebia.iot.utils.SparkTestUtils
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
    val columnNameToOrder = "name"

    // When
    val limitedNumberOfDataAsJsonString = DataFrameTransformation.getLimitedNumberOfDataAsJsonString(preparedData, columnNameToOrder)

    //Then
    val expectedLimitedNumberOfDataAsJsonString = "[{\"name\":\"Ana\",\"age\":24},{\"name\":\"Andy\",\"age\":32},{\"name\":\"Hakima\",\"age\":24},{\"name\":\"Laurie\",\"age\":24},{\"name\":\"Mariam\",\"age\":24},{\"name\":\"Marie\",\"age\":24},{\"name\":\"Nadia\",\"age\":21}]"
    limitedNumberOfDataAsJsonString shouldBe expectedLimitedNumberOfDataAsJsonString
  }
}
