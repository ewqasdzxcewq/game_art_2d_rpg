extends Control

const TRAIL_DELAY := 0.35
const TRAIL_TIME := 0.4
const PULSE_SCALE := 1.1
const SHAKE_OFFSETS := [Vector2(-3, 0), Vector2(3, 1), Vector2(-2, -1), Vector2(1, 0)]

var health := 10 setget set_health
var max_health := 10 setget set_max_health
var trail_tween: SceneTreeTween

onready var bar: Panel = $Bar
onready var fill: ProgressBar = $Bar/Fill
onready var trail: ProgressBar = $Bar/Trail
onready var rest_position := bar.rect_position

func set_health(value: int) -> void:
	var previous := health
	health = int(clamp(value, 0, max_health))
	if fill == null:
		return
	fill.value = health
	if trail_tween:
		trail_tween.kill()
	if health < previous:
		trail_tween = trail.create_tween()
		trail_tween.tween_property(trail, "value", float(health), TRAIL_TIME).set_delay(TRAIL_DELAY)
		_shake()
		return
	trail.value = health
	if health > previous:
		_pulse()

func set_max_health(value: int) -> void:
	max_health = int(max(value, 1))
	if fill != null:
		fill.max_value = max_health
		trail.max_value = max_health
	self.health = int(min(health, max_health))

func _ready() -> void:
	bar.rect_pivot_offset = bar.rect_size / 2.0
	self.max_health = PlayerStats.max_health
	self.health = PlayerStats.health
	PlayerStats.connect("health_changed", self, "set_health")
	PlayerStats.connect("max_health_changed", self, "set_max_health")

func _shake() -> void:
	var tween := bar.create_tween()
	for offset in SHAKE_OFFSETS:
		tween.tween_property(bar, "rect_position", rest_position + offset, 0.04)
	tween.tween_property(bar, "rect_position", rest_position, 0.04)

func _pulse() -> void:
	var tween := bar.create_tween()
	tween.tween_property(bar, "rect_scale", Vector2.ONE * PULSE_SCALE, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bar, "rect_scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE)
