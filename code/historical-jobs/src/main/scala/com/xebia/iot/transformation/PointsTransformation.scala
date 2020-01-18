package com.xebia.iot.transformation

import com.xebia.iot.data.{AveragePointByDeviceAndDate, DeviceAndDate, Point, PointValuesSummed}
import org.apache.spark.sql.functions._
import org.apache.spark.sql.{DataFrame, Dataset, KeyValueGroupedDataset, SparkSession}


object PointsTransformation {

  def getDatSetAsPoint(dataFrame: DataFrame)(implicit spark: SparkSession): Dataset[Point]={
    import spark.implicits._
    dataFrame
      .withColumn("year", year(col("timestamp")))
      .withColumn("month", month(col("timestamp")))
      .withColumn("day", dayofmonth(col("timestamp")))
      .as[Point]
  }

  def getAveragePointPerDeviceAndDate(points: Dataset[Point])(implicit spark: SparkSession): Dataset[AveragePointByDeviceAndDate]={
    import spark.implicits._
    val pointValuesSummedWithDeviceAndDate = points.map(point=> {
      val pointValuesSummed = PointValuesSummed(
        temperature = point.temperature,
        humidity = point.humidity,
        moisture = point.moisture,
        count = 1)
      val deviceAndDate = DeviceAndDate(
        device = point.device,
        day = point.day,
        month = point.month,
        year = point.year)
      (deviceAndDate, pointValuesSummed)
    })
    val pointValuesSummedWByDeviceAndDate = pointValuesSummedWithDeviceAndDate.rdd.reduceByKey((pointValuesSummed1, pointValuesSummed2)=>{
      PointValuesSummed(
        temperature = pointValuesSummed1.temperature + pointValuesSummed2.temperature,
        humidity = pointValuesSummed1.humidity + pointValuesSummed2.humidity,
        moisture = pointValuesSummed1.moisture + pointValuesSummed2.moisture,
        count = pointValuesSummed1.count + pointValuesSummed2.count
      )
    })

    val averagePointsPerDeviceAndDate = pointValuesSummedWByDeviceAndDate.map(elt =>{
      AveragePointByDeviceAndDate(
        device = elt._1.device,
        day = elt._1.day,
        month = elt._1.month,
        year = elt._1.year,
        temperature = elt._2.temperature / elt._2.count,
        humidity = elt._2.humidity / elt._2.count,
        moisture = elt._2.moisture / elt._2.count
      )
    })
    averagePointsPerDeviceAndDate.toDS()
  }
}