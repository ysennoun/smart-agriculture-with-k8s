package com.xebia.iot.data

case class DataPath(esAliasForIncomingData: String,
                    esAliasForHistoricalJobs: String,
                    s3PreparedDataPath: String)