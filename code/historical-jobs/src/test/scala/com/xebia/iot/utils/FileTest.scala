package com.xebia.iot.utils

import org.scalatest.{FlatSpec, Matchers}

class FileTest extends FlatSpec with Matchers {

  "From a object file path" should "get a new path composed with a destination folder path" in {
    // Given
    val sourceFilePath = "s3://path/to/soource/file.json"
    val destinationFolderPath = "s3://other-path/to/destination/"

    // When
    val filePath = CustomFile.getFilePath(sourceFilePath, destinationFolderPath)

    // Then
    val expectedFilePath = "s3://other-path/to/destination/file.json"
    filePath should equal(expectedFilePath)
  }
}
