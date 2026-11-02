extends Node

export(int) var max_health = 1 setget set_max_health
var health = max_health setget set_health

signal no_health
signal health_changed(value)
signal max_health_changed(value)

func set_max_health(value):
	max_health = value
	self.health = min(health, max_health)
	emit_signal("max_health_changed", max_health)

func set_health(value):
	var new_health = int(clamp(value, 0, max_health))
	if new_health == health:
		return
	var was_alive = health > 0
	health = new_health
	emit_signal("health_changed", health)
	if was_alive and health == 0:
		emit_signal("no_health")
		
func _ready():
	self.health = max_health
