package com.xebia.iot.utils

import org.apache.spark.{SparkConf, SparkContext}
import org.apache.spark.sql.SparkSession

trait SparkTestUtils {

  lazy val sparkConf: SparkConf =
    new SparkConf()
      .setAppName("RawDataToPreparedData")
      .setMaster("local[*]")

  implicit lazy val sc: SparkContext = SparkContext.getOrCreate(sparkConf)

  implicit lazy val spark: SparkSession = SparkSession.builder().config(sparkConf).getOrCreate()

  spark.conf.set("spark.sql.sources.partitionColumnTypeInference.enabled", "false")
  sc.hadoopConfiguration.set("fs.s3a.endpoint", "http://localhost:9000")

}
