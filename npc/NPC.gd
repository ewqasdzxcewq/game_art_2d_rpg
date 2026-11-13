extends KinematicBody2D

const TalkPrompt = preload("res://npc/TalkPrompt.gd")
const BREATHE_SPEED := 2.0
const BREATHE_AMOUNT := 0.03

var player_near := false
var prompt: Node
var time := randf() * TAU

onready var dialogue = get_node_or_null("DialoguePlayer")
onready var sprite: AnimatedSprite = $AnimatedSprite
onready var base_scale := sprite.scale
onready var base_y := sprite.position.y
onready var half_height: float = sprite.frames.get_frame(sprite.animation, 0).get_height() * base_scale.y / 2.0

func _ready() -> void:
	prompt = TalkPrompt.new()
	add_child(prompt)

func _process(delta: float) -> void:
	time += delta
	var breath := sin(time * BREATHE_SPEED) * BREATHE_AMOUNT
	sprite.scale = base_scale * Vector2(1.0 - breath * 0.5, 1.0 + breath)
	sprite.position.y = base_y - half_height * breath
	prompt.show_at(global_position, player_near and not _talking())

func _unhandled_input(event: InputEvent) -> void:
	if player_near and dialogue and event.is_action_pressed("use"):
		dialogue.play_dialogue()

func _on_TalkArea_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = true

func _on_TalkArea_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = false

func _talking() -> bool:
	return dialogue != null and dialogue.is_dialogue_active
