package com.xebia.iot.exception

sealed abstract class JobException(message: String) extends Exception(message)

object JobException {

  case class WrongNumberOfArgumentsException(message: String) extends JobException(message)
  case class WrongJobException(message: String) extends JobException(message)

}
