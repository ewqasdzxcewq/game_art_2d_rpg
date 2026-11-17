extends CanvasLayer

const STICK_CENTER := Vector2(72, 288)
const STICK_RADIUS := 40.0
const STICK_ZONE_WIDTH := 320.0
const KNOB_RADIUS := 16.0
const DEADZONE := 0.2
const TOUCH_MARGIN := 8.0
const BASE_COLOR := Color(0.1, 0.07, 0.06, 0.45)
const PRESSED_COLOR := Color(0.32, 0.12, 0.08, 0.8)
const EDGE_COLOR := Color(0.95, 0.72, 0.38, 0.8)
const TEXT_COLOR := Color(1, 0.94, 0.78)
const BUTTONS := [
	{"action": "ui_accept", "text": "Attack", "position": Vector2(584, 296), "radius": 30.0},
	{"action": "dash", "text": "Dash", "position": Vector2(516, 324), "radius": 22.0},
	{"action": "use", "text": "", "position": Vector2(532, 254), "radius": 22.0},
	{"action": "heal", "text": "Heal", "position": Vector2(600, 228), "radius": 22.0},
	{"action": "ui_cancel", "text": "II", "position": Vector2(616, 24), "radius": 14.0},
]

var stick_index := -1
var stick_vector := Vector2.ZERO
var pressed := {}
var canvas: Control
var use_text := ""

func _ready() -> void:
	if not OS.has_touchscreen_ui_hint():
		set_process(false)
		queue_free()
		return
	pause_mode = PAUSE_MODE_PROCESS
	layer = 100
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.connect("draw", self, "_draw_controls")
	add_child(canvas)

func _exit_tree() -> void:
	if stick_index >= 0:
		_set_stick(Vector2.ZERO)
	for action in pressed.values():
		_send(action, false)

func _process(_delta: float) -> void:
	var text := ""
	for node in get_tree().get_nodes_in_group("interactable"):
		text = node.interact_text()
		if text != "":
			break
	if text == use_text:
		return
	use_text = text
	canvas.update()

func _visible(button: Dictionary) -> bool:
	return button.action != "use" or use_text != ""

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_pressed(event.index, event.position)
		else:
			_touch_released(event.index)
	elif event is InputEventScreenDrag and event.index == stick_index:
		_move_stick(event.position)

func _touch_pressed(index: int, position: Vector2) -> void:
	for button in BUTTONS:
		if _visible(button) and position.distance_to(button.position) <= button.radius + TOUCH_MARGIN:
			pressed[index] = button.action
			_send(button.action, true)
			canvas.update()
			return
	if stick_index < 0 and position.x < STICK_ZONE_WIDTH:
		stick_index = index
		_move_stick(position)

func _touch_released(index: int) -> void:
	if index == stick_index:
		stick_index = -1
		_set_stick(Vector2.ZERO)
	elif pressed.has(index):
		_send(pressed[index], false)
		pressed.erase(index)
		canvas.update()

func _move_stick(position: Vector2) -> void:
	_set_stick((position - STICK_CENTER).limit_length(STICK_RADIUS) / STICK_RADIUS)

func _set_stick(value: Vector2) -> void:
	stick_vector = value
	_set_strength("ui_left", -value.x)
	_set_strength("ui_right", value.x)
	_set_strength("ui_up", -value.y)
	_set_strength("ui_down", value.y)
	canvas.update()

func _set_strength(action: String, strength: float) -> void:
	if strength > DEADZONE:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)

func _send(action: String, is_pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = is_pressed
	Input.parse_input_event(event)

func _draw_controls() -> void:
	canvas.draw_circle(STICK_CENTER, STICK_RADIUS, BASE_COLOR)
	canvas.draw_arc(STICK_CENTER, STICK_RADIUS, 0.0, TAU, 32, EDGE_COLOR)
	canvas.draw_circle(STICK_CENTER + stick_vector * STICK_RADIUS, KNOB_RADIUS, EDGE_COLOR)
	var font := canvas.get_font("font", "Label")
	for button in BUTTONS:
		if not _visible(button):
			continue
		var text: String = use_text if button.action == "use" else button.text
		canvas.draw_circle(button.position, button.radius, PRESSED_COLOR if pressed.values().has(button.action) else BASE_COLOR)
		canvas.draw_arc(button.position, button.radius, 0.0, TAU, 32, EDGE_COLOR)
		var size := font.get_string_size(text)
		canvas.draw_string(font, button.position - size / 2 + Vector2(0, font.get_ascent()), text, TEXT_COLOR)
