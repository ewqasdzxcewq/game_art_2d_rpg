extends VideoPlayer

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene("res://test world 2.tscn")

func _on_VideoPlayer_finished():
	get_tree().change_scene("res://test world 2.tscn")
