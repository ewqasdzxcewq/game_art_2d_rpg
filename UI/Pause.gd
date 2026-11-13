extends Control

const PauseSound = preload("res://audio and videos/Pause.wav")
const UnpauseSound = preload("res://audio and videos/Unpause.wav")
const UITheme = preload("res://UI/theme.tres")
const FADE_TIME := 0.15

var resume_button: Button

onready var overlay: ColorRect = $"Black Overlay"
onready var menu: VBoxContainer = get_node("../CanvasLayer/VBoxContainer")

func _ready() -> void:
	get_parent().pause_mode = Node.PAUSE_MODE_PROCESS
	overlay.modulate.a = 0.0
	menu.modulate.a = 0.0
	menu.theme = UITheme
	menu.add_constant_override("separation", 6)
	menu.add_child(_title("Paused"))
	resume_button = _button("Resume", "_on_resume_pressed")
	menu.add_child(resume_button)
	menu.add_child(_button("Main Menu", "_on_main_menu_pressed"))
	for bus_name in Game.VOLUME_BUSES:
		menu.add_child(_row(bus_name, _slider(Game.get_bus_volume(bus_name), "_on_volume_changed", [bus_name])))
	menu.add_child(_row("Shake", _slider(Game.get_shake_strength(), "_on_shake_changed")))
	menu.add_child(_row("FPS", _fps_option()))

func _title(text: String) -> Label:
	var title := Label.new()
	title.text = text
	title.align = Label.ALIGN_CENTER
	return title

func _button(text: String, method: String) -> Button:
	var button := Button.new()
	button.text = text
	button.rect_min_size = Vector2(160, 24)
	button.connect("pressed", self, method)
	return button

func _row(text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.rect_min_size.x = 48
	row.add_child(label)
	control.size_flags_horizontal = SIZE_EXPAND_FILL
	control.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(control)
	return row

func _slider(value: float, method: String, binds := []) -> HSlider:
	var slider := HSlider.new()
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.connect("value_changed", self, method, binds)
	return slider

func _fps_option() -> OptionButton:
	var option := OptionButton.new()
	for fps in Game.FPS_OPTIONS:
		option.add_item(str(fps) if fps > 0 else "Max")
	option.selected = max(Game.FPS_OPTIONS.find(Game.get_max_fps()), 0)
	option.connect("item_selected", self, "_on_fps_selected")
	return option

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_set_paused(not get_tree().paused)
		get_tree().set_input_as_handled()

func _on_resume_pressed() -> void:
	_set_paused(false)

func _on_main_menu_pressed() -> void:
	_set_paused(false)
	Game.change_scene("res://UI/Main Menu/MainMenu.tscn")

func _on_volume_changed(value: float, bus_name: String) -> void:
	Game.set_bus_volume(bus_name, value)

func _on_shake_changed(value: float) -> void:
	Game.set_shake_strength(value)

func _on_fps_selected(index: int) -> void:
	Game.set_max_fps(Game.FPS_OPTIONS[index])

func _set_paused(value: bool) -> void:
	get_tree().paused = value
	Game.play_sfx(PauseSound if value else UnpauseSound)
	overlay.visible = true
	menu.visible = true
	var tween := create_tween().set_parallel()
	tween.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(overlay, "modulate:a", 1.0 if value else 0.0, FADE_TIME)
	tween.tween_property(menu, "modulate:a", 1.0 if value else 0.0, FADE_TIME)
	if value:
		resume_button.grab_focus()
	else:
		tween.chain().tween_callback(overlay, "hide")
		tween.tween_callback(menu, "hide")
