extends VideoPlayer

const UITheme = preload("res://UI/theme.tres")

export(String, FILE, "*.tscn") var next_scene := "res://UI/Main Menu/MainMenu.tscn"

func _ready() -> void:
	Game.stop_music()
	if not is_playing():
		call_deferred("_finish")
		return
	var skip := Button.new()
	skip.text = "Skip"
	skip.theme = UITheme
	skip.rect_min_size = Vector2(64, 24)
	skip.focus_mode = Control.FOCUS_NONE
	skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip.connect("pressed", self, "_finish")
	add_child(skip)
	skip.set_anchors_and_margins_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 8)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_finish()

func _on_VideoPlayer_finished() -> void:
	_finish()

func _finish() -> void:
	stop()
	Game.change_scene(next_scene)
