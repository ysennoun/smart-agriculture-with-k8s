//package com.xebia.iot
//
//import org.apache.spark.sql.SparkSession
//import org.elasticsearch.spark._
//
//
//object ElasticSparkHelloWorld {
//  def main(args: Array[String]) {
//
//    // initialise spark context
//    implicit val spark = SparkSession.builder.getOrCreate()
//    implicit val sc = spark.sparkContext
//    sc.getConf.getAll.toSeq.foreach(println)
//
//
//    val numbers = Map("one" -> 1, "two" -> 2, "three" -> 3)
//    val airports = Map("arrival" -> "Otopeni", "SFO" -> "San Fran")
//
//    sc.makeRDD(
//      Seq(numbers, airports)
//    ).saveToEs("spark/docs")
//  }
//}