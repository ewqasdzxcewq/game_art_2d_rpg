extends Node

const UITheme = preload("res://UI/theme.tres")
const OFFSET := Vector2(-20, -76)
const BOB_HEIGHT := 2.0
const BOB_SPEED := 4.0
const FADE_TIME := 0.15

var text := "Talk"
var label := Label.new()
var showing := false
var time := 0.0

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	label.theme = UITheme
	label.text = text if OS.has_touchscreen_ui_hint() else "E  " + text
	label.modulate.a = 0.0
	layer.add_child(label)

func show_at(world_position: Vector2, show: bool) -> void:
	if show != showing:
		showing = show
		label.create_tween().tween_property(label, "modulate:a", 1.0 if show else 0.0, FADE_TIME)
	if label.modulate.a <= 0.0:
		return
	time += get_process_delta_time()
	var screen: Vector2 = get_parent().get_viewport().get_canvas_transform().xform(world_position)
	label.rect_position = screen + OFFSET + Vector2(0, sin(time * BOB_SPEED) * BOB_HEIGHT)
