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

	turn_off_player()
	is_dialogue_active = true
	$DialogBox.visible = true
	current_dialogue = -1
	next_line()

func _input(event):
	if not is_dialogue_active:
		return
	
	if event.is_action_pressed("ui_accept"):
		next_line()

func next_line():
	current_dialogue += 1
	
	if current_dialogue >= len(dialogue):
		$Timer.start()
		$DialogBox.visible = false
		turn_on_player()
		return

	$DialogBox/Name.text = dialogue[current_dialogue]['name']
	$DialogBox/Message.text = dialogue[current_dialogue]['message']

func load_dialogue():
	var file = File.new()
	if file.file_exists(dialogue_file):
		file.open(dialogue_file, file.READ)
		return parse_json(file.get_as_text())

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
