extends Node

const SAVE_PATH := "user://save.cfg"

var last_position = null setget set_last_position

func _ready() -> void:
	var save := ConfigFile.new()
	save.load(SAVE_PATH)
	if save.has_section_key("checkpoint", "position"):
		last_position = save.get_value("checkpoint", "position")

func set_last_position(value) -> void:
	last_position = value
	var save := ConfigFile.new()
	save.set_value("checkpoint", "position", value)
	save.save(SAVE_PATH)
