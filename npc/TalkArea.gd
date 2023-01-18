extends Area2D

func _input(event):
	if event.is_action_pressed("ui_accept") and len(get_overlapping_bodies()) > 0:
		start_dialogue()
		
func start_dialogue():
	var dialogue = get_parent().get_node("DialoguePlayer")
	
	if dialogue:
		dialogue.play_dialogue()
