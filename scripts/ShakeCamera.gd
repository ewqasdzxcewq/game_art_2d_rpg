extends Camera2D

const MAX_OFFSET := 7.0
const DECAY := 2.5

var trauma := 0.0

func _ready() -> void:
	add_to_group("camera")
	set_process(false)

func shake(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)
	set_process(true)

func _process(delta: float) -> void:
	trauma = max(trauma - DECAY * delta, 0.0)
	var power := trauma * trauma
	offset = Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0)) * MAX_OFFSET * power
	if trauma == 0.0:
		set_process(false)
