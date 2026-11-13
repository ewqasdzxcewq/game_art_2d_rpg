extends Area2D

func get_push_vector() -> Vector2:
	var areas := get_overlapping_areas()
	if areas.empty():
		return Vector2.ZERO
	return areas[0].global_position.direction_to(global_position)
