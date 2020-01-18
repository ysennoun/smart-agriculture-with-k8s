package com.xebia.iot.transformation

import com.xebia.iot.utils.SparkTestUtils
import org.apache.spark.sql.Row
import org.apache.spark.sql.types.{BooleanType, StringType, StructField, StructType}
import org.scalatest.{FlatSpec, Matchers}

class DataFrameTransformationTest extends FlatSpec with Matchers with SparkTestUtils {

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

    // When`
    val updateDf = DataFrameTransformation.insertColumnInDataFrame(df, "new_column", true)

    //Then
    val expectedData = Seq(
      Row("bat", false, true),
      Row("mouse", false, true),
      Row("horse", false, true)
    )

    updateDf.collect().toSeq shouldBe expectedData
  }
}
