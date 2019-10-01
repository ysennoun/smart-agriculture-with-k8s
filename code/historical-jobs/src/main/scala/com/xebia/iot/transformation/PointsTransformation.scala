package com.xebia.iot.transformation

import com.xebia.iot.data.{MeanOfPoints, Point}
import com.xebia.iot.utils.CustomDate.{getCurrentTimestamp, getTimestampsOverAWeek}
import org.apache.spark.sql.functions._
import org.apache.spark.sql.{DataFrame, Dataset, SparkSession}


object PointsTransformation {

  def getDataSetAsMeanOfPoint(dataSetAsPoint: Dataset[Point])(implicit spark: SparkSession): Dataset[MeanOfPoints]={
    import spark.implicits._
    val currentTimestamp = getCurrentTimestamp()
    val timestamps = getTimestampsOverAWeek(currentTimestamp)
    dataSetAsPoint
      //filter data over the last 7 days
      .filter(elt =>
        elt.timestamp.getTime >= timestamps.timestampAtMidnightAWeekAgo.getTime
          &&  elt.timestamp.getTime <= timestamps.timestampAtMidnight.getTime
      )
      .groupBy(
        col("device"),
        hour(col("timestamp")).alias("hour")
      )
      .agg(
        avg(col("temperature")).alias("meanTemperature"),
        avg(col("humidity")).alias("meanHumidity"),
        avg(col("moisture")).alias("meanMoisture")
      )
      .withColumn("timestampFrom", lit(timestamps.timestampAtMidnightAWeekAgo))
      .withColumn("timestampTo", lit(timestamps.timestampAtMidnight))
      .withColumn("year", year(col("timestampTo")))
      .withColumn("month", month(col("timestampTo")))
      .withColumn("day", dayofmonth(col("timestampTo")))
      .as[MeanOfPoints]
  }


  def getDatSetAsPoint(dataFrame: DataFrame)(implicit spark: SparkSession): Dataset[Point]={
    import spark.implicits._
    dataFrame
      .withColumn("year", year(col("timestamp")))
      .withColumn("month", month(col("timestamp")))
      .withColumn("day", dayofmonth(col("timestamp")))
      .as[Point]
  }
}