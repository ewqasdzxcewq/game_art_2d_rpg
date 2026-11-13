extends Area2D

const SavedSound = preload("res://audio and videos/Menu Select.wav")
const UITheme = preload("res://UI/theme.tres")
const ACTIVE_GLOW := Color(0.5, 0.7, 1.0)
const LABEL_OFFSET := Vector2(-36, -64)
const LABEL_RISE := 10.0

var label := Label.new()

onready var glow: Light2D = $Glow

func _ready() -> void:
	$AnimationPlayer.play("default")
	var layer := CanvasLayer.new()
	layer.layer = 45
	add_child(layer)
	label.theme = UITheme
	label.text = "Checkpoint"
	label.add_color_override("font_color", Color(0.65, 0.9, 1))
	label.modulate.a = 0.0
	layer.add_child(label)
	var pulse := glow.create_tween().set_loops()
	pulse.tween_property(glow, "energy", 0.55, 1.2).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(glow, "energy", 0.35, 1.2).set_trans(Tween.TRANS_SINE)

func _on_CheckpointObject_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	PlayerStats.health = PlayerStats.max_health
	if Checkpoint.last_position == global_position:
		return
	Checkpoint.last_position = global_position
	$AnimationPlayer.play("active")
	glow.create_tween().tween_property(glow, "color", ACTIVE_GLOW, 0.4)
	Game.play_sfx(SavedSound)
	_show_label()

func _show_label() -> void:
	var start: Vector2 = get_viewport().get_canvas_transform().xform(global_position) + LABEL_OFFSET
	var tween := label.create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.2).from(0.0)
	tween.parallel().tween_property(label, "rect_position:y", start.y - LABEL_RISE, 1.4).from(start.y) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	label.rect_position.x = start.x
