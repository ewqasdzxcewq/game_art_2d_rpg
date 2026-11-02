extends KinematicBody2D

var in_area = false
var prompt

func _ready():
	prompt = preload("res://npc/TalkPrompt.gd").new()
	add_child(prompt)

func _process(_delta):
	in_area = $TalkArea.get_overlapping_bodies().size() > 0
	prompt.show_at(global_position, in_area and not _talking())

func _input(event):
	if event.is_action_pressed("use") and in_area:
		start_dialogue()

func _on_TalkArea_body_exited(_body):
	in_area = false

func _on_TalkArea_body_entered(_body):
	in_area = true

func start_dialogue():
	var dialogue = get_node("DialoguePlayer")
	if dialogue:
		dialogue.play_dialogue()

func _talking():
	var dialogue = get_node("DialoguePlayer")
	return dialogue and dialogue.is_dialogue_active
