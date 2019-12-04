package com.xebia.iot.transformation

import com.xebia.iot.data.Point
import org.apache.spark.sql.functions._
import org.apache.spark.sql.{DataFrame, Dataset, SparkSession}


object PointsTransformation {

  def getDatSetAsPoint(dataFrame: DataFrame)(implicit spark: SparkSession): Dataset[Point]={
    import spark.implicits._
    dataFrame
      .withColumn("year", year(col("timestamp")))
      .withColumn("month", month(col("timestamp")))
      .withColumn("day", dayofmonth(col("timestamp")))
      .as[Point]
  }
}