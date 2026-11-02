extends Control

onready var menu = get_node("../CanvasLayer/VBoxContainer")

func _ready():
	_build_menu()
	_process_while_paused(get_parent())

func _build_menu():
	menu.alignment = BoxContainer.ALIGN_CENTER
	menu.add_child(_title("Paused"))
	menu.add_child(_button("Resume", "_on_Button_pressed"))
	menu.add_child(_button("Main Menu", "_on_main_menu_pressed"))

func _title(text):
	var title = Label.new()
	title.text = text
	title.align = Label.ALIGN_CENTER
	title.add_color_override("font_color", Color(1, 0.94, 0.78))
	return title

func _button(text, method):
	var button = Button.new()
	button.text = text
	button.rect_min_size = Vector2(160, 28)
	button.connect("pressed", self, method)
	return button

func _process_while_paused(node):
	node.pause_mode = Node.PAUSE_MODE_PROCESS
	for child in node.get_children():
		_process_while_paused(child)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_set_paused(not get_tree().paused)
		get_tree().set_input_as_handled()

func _on_Button_pressed():
	_set_paused(false)

func _on_main_menu_pressed():
	_set_paused(false)
	get_tree().change_scene("res://UI/Main Menu/MainMenu.tscn")

func _set_paused(value):
	get_tree().paused = value
	$"Black Overlay".visible = value
	menu.visible = value
