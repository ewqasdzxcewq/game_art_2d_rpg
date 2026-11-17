extends Area2D

const SavedSound = preload("res://audio and videos/Menu Select.wav")
const TalkPrompt = preload("res://npc/TalkPrompt.gd")
const ACTIVE_GLOW := Color(0.5, 0.7, 1.0)
const LABEL_COLOR := Color(0.65, 0.9, 1)
const LABEL_OFFSET := Vector2(-36, -100)

var player_near := false
var prompt: Node

onready var glow: Light2D = $Glow

func _ready() -> void:
	add_to_group("interactable")
	$AnimationPlayer.play("default")
	prompt = TalkPrompt.new()
	prompt.text = "Rest"
	add_child(prompt)
	var pulse := glow.create_tween().set_loops()
	pulse.tween_property(glow, "energy", 0.55, 1.2).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(glow, "energy", 0.35, 1.2).set_trans(Tween.TRANS_SINE)

func _process(_delta: float) -> void:
	prompt.show_at(global_position, player_near)

func _unhandled_input(event: InputEvent) -> void:
	if player_near and event.is_action_pressed("use"):
		rest()

func interact_text() -> String:
	return "Rest" if player_near else ""

func rest() -> void:
	PlayerStats.health = PlayerStats.max_health
	get_tree().call_group("player", "refill_gourd")
	get_tree().call_group("mob_respawner", "respawn")
	Game.play_sfx(SavedSound)
	Game.popup_label(global_position + LABEL_OFFSET, "Checkpoint", LABEL_COLOR)
	if Checkpoint.last_position == global_position:
		return
	Checkpoint.last_position = global_position
	$AnimationPlayer.play("active")
	glow.create_tween().tween_property(glow, "color", ACTIVE_GLOW, 0.4)

func _on_CheckpointObject_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = true

func _on_CheckpointObject_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = false
