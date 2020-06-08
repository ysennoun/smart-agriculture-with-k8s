package com.xebia.iot.utils

import org.apache.log4j.Logger

trait Logging {
  val logger: Logger = Logger.getLogger(getClass.getName)
}
