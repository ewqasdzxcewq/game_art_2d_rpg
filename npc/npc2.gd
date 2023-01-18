extends KinematicBody2D

var in_area = false

func _input(event):
	if event.is_action_pressed("ui_accept") and in_area:
		start_dialogue()
		

func _on_TalkArea_body_exited(body):
	in_area = false
	print(in_area)
		
func _on_TalkArea_body_entered(_body):
	in_area = true
	print(in_area)
	
	
func start_dialogue():
	var dialogue = get_node("DialoguePlayer")
	
	if dialogue:
		dialogue.play_dialogue()



