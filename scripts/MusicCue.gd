extends Node

export(AudioStream) var music

func _ready() -> void:
	Game.play_music(music)
