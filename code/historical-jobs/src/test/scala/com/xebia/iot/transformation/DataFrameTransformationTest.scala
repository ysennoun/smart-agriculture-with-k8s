package com.xebia.iot.transformation

import com.xebia.iot.utils.SparkTestUtils
import org.apache.spark.sql.Row
import org.apache.spark.sql.types.{BooleanType, StringType, StructField, StructType}
import org.scalatest.{FlatSpec, Matchers}

class DataFrameTransformationTest extends FlatSpec with Matchers with SparkTestUtils  {

  it should "update column valmue of a dataframe" in {

    // Given
    import spark.implicits._
    val data = Seq(
      Row("bat", false),
      Row("mouse", false),
      Row("horse", false)
    )

    val someSchema = List(
      StructField("word", StringType, true),
      StructField("value", BooleanType, true)
    )

    val df = spark.createDataFrame(
      spark.sparkContext.parallelize(data),
      StructType(someSchema)
    )

    // When
    val updateDf = DataFrameTransformation.updateColumnValueInDataFrame(df, "value", true)

    //Then
    val expectedData = Seq(
      Row("bat", true),
      Row("mouse", true),
      Row("horse", true)
    )

    updateDf.collect().toSeq shouldBe expectedData
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
