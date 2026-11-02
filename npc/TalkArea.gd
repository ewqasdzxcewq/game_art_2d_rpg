extends Area2D

var prompt

func _ready():
	prompt = preload("res://npc/TalkPrompt.gd").new()
	add_child(prompt)

func _process(_delta):
	var near = get_overlapping_bodies().size() > 0
	prompt.show_at(global_position, near and not _talking())

func _input(event):
	if event.is_action_pressed("use") and get_overlapping_bodies().size() > 0:
		start_dialogue()

func start_dialogue():
	var dialogue = get_parent().get_node("DialoguePlayer")
	if dialogue:
		dialogue.play_dialogue()

func _talking():
	var dialogue = get_parent().get_node("DialoguePlayer")
	return dialogue and dialogue.is_dialogue_active
