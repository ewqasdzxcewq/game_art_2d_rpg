extends Node

const SAVE_PATH := "user://save.cfg"
const HEALTH_UPGRADE := 2
const XP_PER_LEVEL := 5
const LEVEL_HEALTH := 1

signal xp_changed(level, xp, xp_needed)

var last_position = null setget set_last_position
var collected := []
var health_upgrades := 0
var damage_upgrades := 0
var gourd_upgrades := 0
var dash_upgrades := 0
var lifesteal := false
var level := 1
var xp := 0
var base_max_health := 0

func _ready() -> void:
	base_max_health = PlayerStats.max_health
	var save := ConfigFile.new()
	save.load(SAVE_PATH)
	if save.has_section_key("checkpoint", "position"):
		last_position = save.get_value("checkpoint", "position")
	collected = save.get_value("progress", "collected", [])
	health_upgrades = save.get_value("progress", "health_upgrades", 0)
	damage_upgrades = save.get_value("progress", "damage_upgrades", 0)
	gourd_upgrades = save.get_value("progress", "gourd_upgrades", 0)
	dash_upgrades = save.get_value("progress", "dash_upgrades", 0)
	lifesteal = save.get_value("progress", "lifesteal", false)
	level = save.get_value("progress", "level", 1)
	xp = save.get_value("progress", "xp", 0)
	_apply_health()

func set_last_position(value) -> void:
	last_position = value
	_save()

func collect(id: String) -> void:
	collected.append(id)
	_apply_health()
	_save()

func reset() -> void:
	collected = []
	health_upgrades = 0
	damage_upgrades = 0
	gourd_upgrades = 0
	dash_upgrades = 0
	lifesteal = false
	level = 1
	xp = 0
	_apply_health()
	self.last_position = null

func xp_needed() -> int:
	return level * XP_PER_LEVEL

func add_xp(amount: int) -> bool:
	if amount <= 0:
		return false
	xp += amount
	var leveled := false
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		leveled = true
	if leveled:
		_apply_health()
		PlayerStats.health = PlayerStats.max_health
	emit_signal("xp_changed", level, xp, xp_needed())
	_save()
	return leveled

func _apply_health() -> void:
	PlayerStats.max_health = base_max_health + health_upgrades * HEALTH_UPGRADE + (level - 1) * LEVEL_HEALTH

func _save() -> void:
	var save := ConfigFile.new()
	save.set_value("checkpoint", "position", last_position)
	save.set_value("progress", "collected", collected)
	save.set_value("progress", "health_upgrades", health_upgrades)
	save.set_value("progress", "damage_upgrades", damage_upgrades)
	save.set_value("progress", "gourd_upgrades", gourd_upgrades)
	save.set_value("progress", "dash_upgrades", dash_upgrades)
	save.set_value("progress", "lifesteal", lifesteal)
	save.set_value("progress", "level", level)
	save.set_value("progress", "xp", xp)
	save.save(SAVE_PATH)
