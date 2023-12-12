extends Node

signal new(message: String)


func new_status(message:String):
	new.emit(message)
