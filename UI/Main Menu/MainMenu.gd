extends Node2D

func _ready():
	$"VBoxContainer/Start Game".grab_focus()

func _on_Start_Game_pressed():
	get_tree().change_scene("res://audio and videos/video/VideoPlayer.tscn")

func _on_Quit_Game_pressed():
	get_tree().quit()

func _on_How_to_play_pressed():
	get_tree().change_scene("res://UI/how to play menu/Tuitorial.tscn")
