extends Node2D

export var desert_end_x := 3000.0

var in_desert := false

onready var sand: CPUParticles2D = $Sand
onready var leaves: CPUParticles2D = $Leaves

func _ready() -> void:
	_set_region(global_position.x < desert_end_x)

func _process(_delta: float) -> void:
	var now_in_desert := global_position.x < desert_end_x
	if now_in_desert != in_desert:
		_set_region(now_in_desert)

func _set_region(desert: bool) -> void:
	in_desert = desert
	sand.emitting = desert
	leaves.emitting = not desert
