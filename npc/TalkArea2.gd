extends Area2D

var in_area = false
	
func _input(event):
	var in_area = false
	
	if event.is_action_pressed("ui_accept") and in_area:
		start_dialogue()
	
func start_dialogue():
	#var dialogue = get_parent().get_node("")
	pass
	
	if dialogue:
		dialogue.play_dialogue()
		
func _on_TalkArea_body_entered(body):
	in_area = true
	print(in_area)

func _on_TalkArea_body_exited(body):
	in_area = false
	print(in_area)
