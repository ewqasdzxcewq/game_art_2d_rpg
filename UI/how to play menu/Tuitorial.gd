extends Node2D

const SelectSound = preload("res://audio and videos/Menu Select.wav")

func _ready() -> void:
	$"ColorRect/VBoxContainer/Start Game".grab_focus()

func _on_Start_Game_pressed() -> void:
	Game.play_sfx(SelectSound)
	Game.change_scene("res://UI/Main Menu/MainMenu.tscn")
