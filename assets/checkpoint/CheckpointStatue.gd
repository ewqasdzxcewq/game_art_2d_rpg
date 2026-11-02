extends Area2D

const saved_sound = preload("res://audio and videos/Menu Select.wav")

var saved_label
var saved_timer

func _ready():
	$AnimationPlayer.play("default")
	var layer = CanvasLayer.new()
	layer.layer = 45
	add_child(layer)
	saved_label = Label.new()
	saved_label.text = "Checkpoint"
	saved_label.visible = false
	saved_label.add_color_override("font_color", Color(0.65, 0.9, 1))
	saved_label.add_color_override("font_color_shadow", Color(0, 0, 0))
	saved_label.add_constant_override("shadow_offset_x", 1)
	saved_label.add_constant_override("shadow_offset_y", 1)
	layer.add_child(saved_label)
	saved_timer = Timer.new()
	saved_timer.one_shot = true
	saved_timer.wait_time = 1.2
	add_child(saved_timer)
	saved_timer.connect("timeout", saved_label, "hide")

func _on_CheckpointObject_body_entered(body):
	if body.name != "Player":
		return
	PlayerStats.health = PlayerStats.max_health
	Checkpoint.last_position = global_position
	$AnimationPlayer.play("active")
	saved_label.rect_position = get_viewport().get_canvas_transform().xform(global_position) + Vector2(-36, -48)
	saved_label.show()
	saved_timer.start()
	var sfx = AudioStreamPlayer.new()
	sfx.stream = saved_sound
	add_child(sfx)
	sfx.play()
	sfx.connect("finished", sfx, "queue_free")
