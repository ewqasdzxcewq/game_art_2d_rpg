extends Node2D

const MoveSound = preload("res://audio and videos/Menu Move.wav")
const SelectSound = preload("res://audio and videos/Menu Select.wav")
const FOCUS_SCALE := Vector2(1.08, 1.08)
const TITLE_RISE := 14.0
const WORLD_SCENE := "res://test world 2.tscn"
const ENDLESS_SCENE := "res://endless/Endless.tscn"

onready var title: Sprite = $ColorRect/IRUGA
onready var buttons: VBoxContainer = $VBoxContainer
onready var continue_button: Button = $VBoxContainer/Continue
onready var start_button: Button = $"VBoxContainer/Start Game"
onready var difficulty_button: Button = $VBoxContainer/Difficulty

func _ready() -> void:
	_update_difficulty_text()
	$VBoxContainer/Endless.text = "Endless (Best %d)" % Game.get_best_score()
	var first := start_button
	if Checkpoint.last_position != null:
		continue_button.show()
		start_button.focus_neighbour_top = start_button.get_path_to(continue_button)
		$"VBoxContainer/Quit Game".focus_neighbour_bottom = $"VBoxContainer/Quit Game".get_path_to(continue_button)
		first = continue_button
	first.grab_focus()
	for button in buttons.get_children():
		button.rect_pivot_offset = button.rect_size / 2.0
		button.connect("focus_entered", self, "_on_button_focus_changed", [button, true])
		button.connect("focus_exited", self, "_on_button_focus_changed", [button, false])
		button.connect("mouse_entered", button, "grab_focus")
	_scale_button(first, true)
	_play_intro()

func _play_intro() -> void:
	var title_y := title.position.y
	title.position.y += TITLE_RISE
	title.modulate.a = 0.0
	buttons.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(title, "modulate:a", 1.0, 0.8)
	tween.tween_property(title, "position:y", title_y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(buttons, "modulate:a", 1.0, 0.6).set_delay(0.5)

func _scale_button(button: Control, focused: bool) -> void:
	button.create_tween().tween_property(button, "rect_scale", FOCUS_SCALE if focused else Vector2.ONE, 0.1)

func _on_button_focus_changed(button: Control, focused: bool) -> void:
	_scale_button(button, focused)
	if focused:
		Game.play_sfx(MoveSound, -6.0)

func _on_Continue_pressed() -> void:
	Game.play_sfx(SelectSound)
	Game.change_scene(WORLD_SCENE)

func _on_Start_Game_pressed() -> void:
	Game.play_sfx(SelectSound)
	Checkpoint.reset()
	Game.change_scene("res://audio and videos/video/VideoPlayer.tscn")

func _on_Endless_pressed() -> void:
	Game.play_sfx(SelectSound)
	Game.change_scene(ENDLESS_SCENE)

func _on_Difficulty_pressed() -> void:
	Game.play_sfx(SelectSound)
	Game.set_difficulty((Game.get_difficulty() + 1) % Game.DIFFICULTY_NAMES.size())
	_update_difficulty_text()

func _update_difficulty_text() -> void:
	difficulty_button.text = "Difficulty: " + Game.DIFFICULTY_NAMES[Game.get_difficulty()]

func _on_Quit_Game_pressed() -> void:
	get_tree().quit()

func _on_How_to_play_pressed() -> void:
	Game.play_sfx(SelectSound)
	Game.change_scene("res://UI/how to play menu/Tuitorial.tscn")
