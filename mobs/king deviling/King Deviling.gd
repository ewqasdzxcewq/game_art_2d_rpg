extends "res://mobs/Enemy.gd"

const BOSS_TINT := Color(0.78, 0.62, 0.66)
const TINT_TIME := 1.5
const STOMP_COOLDOWN := 6.0
const STOMP_WINDUP := 1.2
const STOMP_ACTIVE := 0.15
const STOMP_RECOVERY := 0.8
const STOMP_TINT := Color(1, 0.4, 0.4)
const STOMP_FILL := Color(1, 0.15, 0.15, 0.25)
const STOMP_EDGE := Color(1, 0.2, 0.2, 0.8)
const ENRAGED_STOMP_COOLDOWN := 4.0
const ENRAGED_SPEED_SCALE := 1.5
const ENRAGED_ATTACK_COOLDOWN_SCALE := 0.6
const ENRAGED_LABEL_OFFSET := Vector2(-60, -220)

export(AudioStream) var boss_music

var engaged := false
var enraged := false
var stomp_cooldown := STOMP_COOLDOWN
var stomp_warning := 0.0 setget set_stomp_warning
var stomp_tween: SceneTreeTween

onready var stomp_shape: CollisionShape2D = $StompHitbox/CollisionShape2D
onready var stomp_radius: float = stomp_shape.shape.radius

func _ready() -> void:
	receives_knockback = false

func _physics_process(delta: float) -> void:
	if dead or state != CHASE:
		return
	if stomp_cooldown > 0.0:
		stomp_cooldown -= delta
		return
	var player = player_detection_zone.player
	if player != null and global_position.distance_to(player.global_position) <= stomp_radius * 0.9:
		start_stomp()

func _draw() -> void:
	if stomp_warning <= 0.0:
		return
	draw_circle(Vector2.ZERO, stomp_radius * stomp_warning, STOMP_FILL)
	draw_arc(Vector2.ZERO, stomp_radius, 0.0, TAU, 64, STOMP_EDGE, 3.0)

func set_stomp_warning(value: float) -> void:
	stomp_warning = value
	update()

func start_stomp() -> void:
	state = ATTACK
	velocity = Vector2.ZERO
	stomp_cooldown = ENRAGED_STOMP_COOLDOWN if enraged else STOMP_COOLDOWN
	_play("idle")
	stomp_tween = create_tween()
	stomp_tween.tween_property(self, "stomp_warning", 1.0, STOMP_WINDUP).from(0.0)
	stomp_tween.parallel().tween_property(sprite, "modulate", STOMP_TINT, STOMP_WINDUP)
	stomp_tween.tween_callback(self, "stomp_impact")
	stomp_tween.tween_interval(STOMP_ACTIVE)
	stomp_tween.tween_callback(stomp_shape, "set_deferred", ["disabled", true])
	stomp_tween.tween_interval(STOMP_RECOVERY)
	stomp_tween.tween_callback(self, "attack_animation_finished")

func stomp_impact() -> void:
	self.stomp_warning = 0.0
	sprite.modulate = Color.white
	stomp_shape.set_deferred("disabled", false)
	Game.flash(sprite)
	Game.shake(0.8)

func _on_Hurtbox_area_entered(area: Area2D) -> void:
	._on_Hurtbox_area_entered(area)
	if dead or enraged or stats.health * 2 > stats.max_health:
		return
	enraged = true
	max_speed = int(max_speed * ENRAGED_SPEED_SCALE)
	attack_cooldown *= ENRAGED_ATTACK_COOLDOWN_SCALE
	Game.flash(sprite, 0.5)
	Game.shake(0.8)
	Game.popup_label(global_position + ENRAGED_LABEL_OFFSET, "The King is enraged!", STOMP_TINT)

func die() -> void:
	if stomp_tween != null:
		stomp_tween.kill()
	self.stomp_warning = 0.0
	stomp_shape.set_deferred("disabled", true)
	.die()

func seek_player() -> void:
	.seek_player()
	if state != CHASE or engaged:
		return
	engaged = true
	Game.shake(0.6)
	Game.play_music(boss_music)
	for tint in get_tree().get_nodes_in_group("world_tint"):
		tint.create_tween().tween_property(tint, "color", BOSS_TINT, TINT_TIME)

func ending_scene() -> void:
	Checkpoint.last_position = null
	Game.change_scene("res://audio and videos/video/ending.tscn")
