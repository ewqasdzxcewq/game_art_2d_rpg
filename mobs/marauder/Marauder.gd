extends "res://mobs/Enemy.gd"

const SPRINT_SPEED_SCALE := 2.5
const SPRINT_TIME := 1.5
const SPRINT_COOLDOWN := 5.0
const SPRINT_MIN_DISTANCE := 120.0
const SPRINT_TINT := Color(1, 0.6, 0.6)

var sprint_time := 0.0
var sprint_cooldown := 0.0

onready var base_speed := max_speed

func _physics_process(delta: float) -> void:
	if dead:
		return
	if sprint_time > 0.0:
		sprint_time -= delta
		if sprint_time <= 0.0:
			end_sprint()
		return
	if sprint_cooldown > 0.0:
		sprint_cooldown -= delta
		return
	var player = player_detection_zone.player
	if state == CHASE and player != null and global_position.distance_to(player.global_position) > SPRINT_MIN_DISTANCE:
		start_sprint()

func start_sprint() -> void:
	sprint_time = SPRINT_TIME
	max_speed = int(base_speed * SPRINT_SPEED_SCALE)
	receives_knockback = false
	knockback = Vector2.ZERO
	sprite.modulate = SPRINT_TINT
	Game.flash(sprite)

func end_sprint() -> void:
	sprint_time = 0.0
	sprint_cooldown = SPRINT_COOLDOWN
	max_speed = base_speed
	receives_knockback = true
	sprite.modulate = Color.white

func start_attack(player: Node2D) -> void:
	if sprint_time > 0.0:
		end_sprint()
	.start_attack(player)
