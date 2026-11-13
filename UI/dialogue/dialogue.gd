extends CanvasLayer

const AdvanceSound = preload("res://audio and videos/Menu Move.wav")
const CHARS_PER_SECOND := 45.0
const SLIDE_OFFSET := 24.0
const SLIDE_TIME := 0.2

export(String, FILE, "*.json") var dialogue_file

var dialogue := []
var current_line := 0
var reading := false
var is_dialogue_active := false
var typing_tween: SceneTreeTween

onready var box: NinePatchRect = $DialogBox
onready var name_label: RichTextLabel = $DialogBox/Name
onready var message_label: RichTextLabel = $DialogBox/Message
onready var continue_label: Label = $DialogBox/Continue
onready var rest_y := box.rect_position.y

func _ready() -> void:
	box.visible = false
	var blink := continue_label.create_tween().set_loops()
	blink.tween_property(continue_label, "modulate:a", 0.3, 0.5)
	blink.tween_property(continue_label, "modulate:a", 1.0, 0.5)

func play_dialogue() -> void:
	if is_dialogue_active:
		return
	dialogue = load_dialogue()
	if dialogue.empty():
		return
	is_dialogue_active = true
	reading = true
	turn_off_player()
	current_line = -1
	_slide_box(true)
	next_line()

func _input(event: InputEvent) -> void:
	if not reading:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("use"):
		get_tree().set_input_as_handled()
		if message_label.percent_visible < 1.0:
			_finish_typing()
		else:
			Game.play_sfx(AdvanceSound, -8.0)
			next_line()

func next_line() -> void:
	current_line += 1
	if current_line >= dialogue.size():
		_end_dialogue()
		return
	var line = dialogue[current_line]
	if typeof(line) != TYPE_DICTIONARY or not line.has("name") or not line.has("message"):
		_end_dialogue()
		return
	name_label.text = line["name"]
	message_label.text = line["message"]
	message_label.percent_visible = 0.0
	continue_label.visible = false
	typing_tween = message_label.create_tween()
	typing_tween.tween_property(message_label, "percent_visible", 1.0, max(message_label.text.length() / CHARS_PER_SECOND, 0.05))
	typing_tween.tween_callback(continue_label, "show")

func _finish_typing() -> void:
	if typing_tween:
		typing_tween.kill()
	message_label.percent_visible = 1.0
	continue_label.visible = true

func load_dialogue() -> Array:
	var file := File.new()
	if dialogue_file == "" or not file.file_exists(dialogue_file):
		return []
	if file.open(dialogue_file, File.READ) != OK:
		return []
	var data = parse_json(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_ARRAY:
		return []
	return data

func _end_dialogue() -> void:
	reading = false
	_slide_box(false)
	$Timer.start()

func _slide_box(opening: bool) -> void:
	box.visible = true
	var tween := box.create_tween().set_parallel()
	tween.tween_property(box, "modulate:a", 1.0 if opening else 0.0, SLIDE_TIME).from(0.0 if opening else 1.0)
	tween.tween_property(box, "rect_position:y", rest_y if opening else rest_y + SLIDE_OFFSET, SLIDE_TIME) \
		.from(rest_y + SLIDE_OFFSET if opening else rest_y) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not opening:
		tween.chain().tween_callback(box, "hide")

func _on_Timer_timeout() -> void:
	is_dialogue_active = false
	turn_on_player()

func turn_on_player() -> void:
	get_tree().call_group("player", "set_active", true)

func turn_off_player() -> void:
	get_tree().call_group("player", "set_active", false)
