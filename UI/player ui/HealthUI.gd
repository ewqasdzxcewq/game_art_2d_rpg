extends Control

var health = 10 setget set_health
var max_health = 10 setget set_max_health

onready var ui_heart_full = $Sprite/HeartUIFull
onready var ui_heart_empty = $Sprite/HeartUIEmpty

func set_health(value):
	health = clamp(value, 0, max_health)
	if ui_heart_full != null:
		ui_heart_full.rect_size.x = health * 15

func set_max_health(value):
	max_health = max(value, 1)
	self.health = min(health, max_health)
	if ui_heart_empty != null:
		ui_heart_empty.rect_size.x = max_health * 15

func _ready():
	self.max_health = PlayerStats.max_health
	self.health = PlayerStats.health
	PlayerStats.connect("health_changed", self, "set_health")
	PlayerStats.connect("max_health_changed", self, "set_max_health")
