extends CanvasLayer

export(String, FILE, "*.json") var dialogue_file

var dialogue = []
var current_dialogue = 0
var is_dialogue_active = false

func _ready():
	$DialogBox.visible = false
	
func play_dialogue():
	if is_dialogue_active:
		return
	
	dialogue = load_dialogue()
	if typeof(dialogue) != TYPE_ARRAY or dialogue.empty():
		_end_dialogue()
		return

	turn_off_player()
	is_dialogue_active = true
	$DialogBox.visible = true
	current_dialogue = -1
	next_line()

func _input(event):
	if not is_dialogue_active:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("use"):
		next_line()

func next_line():
	current_dialogue += 1
	
	if typeof(dialogue) != TYPE_ARRAY or current_dialogue >= dialogue.size():
		_end_dialogue()
		return

	var line = dialogue[current_dialogue]
	if typeof(line) != TYPE_DICTIONARY or not line.has("name") or not line.has("message"):
		_end_dialogue()
		return
	$DialogBox/Name.text = line["name"]
	$DialogBox/Message.text = line["message"]

func load_dialogue():
	var file = File.new()
	if dialogue_file == "" or not file.file_exists(dialogue_file):
		return []
	if file.open(dialogue_file, file.READ) != OK:
		return []
	var data = parse_json(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_ARRAY:
		return []
	return data

func _end_dialogue():
	$DialogBox.visible = false
	$Timer.start()
	turn_on_player()

func _on_Timer_timeout():
	is_dialogue_active = false
	
func turn_on_player():
	var player = get_tree().get_root().find_node("Player", true, false)
	if player:
		player.set_active(true)
		
func turn_off_player():
	var player = get_tree().get_root().find_node("Player", true, false)
	if player:
		player.set_active(false)
