package com.xebia.iot.job

import java.sql.Timestamp

import com.xebia.iot.date.Timestamps
import org.apache.spark.sql.{DataFrame, Dataset, SaveMode, SparkSession}
import org.apache.spark.sql.functions.{avg, col, dayofmonth, hour, lit, month, year}


case class Point(device: String,
                 timestamp: Timestamp,
                 temperature: Double,
                 humidity: Double,
                 moisture: Double)
case class MeanOfPoints(device: String,
                        timestampFrom: Timestamp,
                        timestampTo: Timestamp,
                        hour: Int,
                        meanTemperature: Double,
                        meanHumidity: Double,
                        meanMoisture: Double,
                        year: Int,
                        month: Int,
                        day: Int)

object HistoricalJob {

  def main(args: Array[String]): Unit = {
    println("toto")
  }

  def convertJsonToParquet(jsonPath: String, parquetPath: String)(implicit spark: SparkSession)={
    val dataFrame = spark.read.json(jsonPath)
    dataFrame
      .coalesce(10)
      .write
      .partitionBy("year","month","day")
      .mode(SaveMode.Append)
      .parquet(parquetPath)
  }

  def getDataSetAsPoint(inputParquetPath: String)(implicit spark: SparkSession): Dataset[Point]={
    import spark.implicits._
    spark.read.parquet(inputParquetPath).as[Point]
  }

  def saveDataFrame(dataFrame: DataFrame, outputParquetPath: String)(implicit spark: SparkSession)={
    dataFrame
      .coalesce(10)
      .write
      .partitionBy("year", "month", "day")
      .parquet(outputParquetPath)
  }

  def getDataSetAsMeanOfPoint(dataSetAsPoint: Dataset[Point])(implicit spark: SparkSession): Dataset[MeanOfPoints]={
    import spark.implicits._
    val timestamps = Timestamps.getTimestamps()
    dataSetAsPoint
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
}