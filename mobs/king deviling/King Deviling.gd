extends "res://mobs/Enemy.gd"

func _ready():
	receives_knockback = false
	._ready()

func ending_scene():
	get_tree().change_scene("res://audio and videos/video/ending.tscn")
