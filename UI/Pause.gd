extends Control

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = true
		$"Black Overlay".visible = true
		#get_parent().get_node("VBoxContainer/Button").visible = true
		
func _on_Button_pressed():
	get_tree().paused = false
	$"Black Overlay".visible = false
	#get_parent().get_node("VBoxContainer").visible = false
