extends Node

var label

func _ready():
	var layer = CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	label = Label.new()
	label.text = "E  Talk"
	label.add_color_override("font_color", Color(1, 0.94, 0.78))
	label.add_color_override("font_color_shadow", Color(0, 0, 0))
	label.add_constant_override("shadow_offset_x", 1)
	label.add_constant_override("shadow_offset_y", 1)
	layer.add_child(label)
	label.visible = false

func show_at(world_position, show):
	label.visible = show
	if not show:
		return
	var screen = get_parent().get_viewport().get_canvas_transform().xform(world_position)
	label.rect_position = screen + Vector2(-22, -56)
