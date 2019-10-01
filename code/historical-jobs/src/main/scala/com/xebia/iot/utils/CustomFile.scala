package com.xebia.iot.utils

object CustomFile {

  def getFilePath(sourceFilePath: String, destinationFolderPath: String): String={
    val fileName = sourceFilePath.split("/").last
    destinationFolderPath.last.toString match {
      case "/" => destinationFolderPath + fileName
      case _ => destinationFolderPath + "/" + fileName
    }
  }
}
