extends KinematicBody2D

const DeathBurst = preload("res://effects/DeathBurst.tscn")
const RUN_START_SPEED := 14.0
const RUN_STOP_SPEED := 5.0
const FLIP_DEADZONE := 8.0
const KNOCKBACK_FORCE := 140.0
const SOFT_PUSH_FORCE := 400.0
const INSANE_HEALTH_SCALE := 2
const LIFESTEAL_HEAL := 1
const LEVEL_UP_OFFSET := Vector2(-24, -40)
const LEVEL_UP_COLOR := Color(1, 0.85, 0.4)

export var acceleration := 300
export var max_speed := 50
export var friction := 200
export var wander_target_range := 4
export var receives_knockback := true
export var attack_range := 40.0
export var attack_cooldown := 1.2
export var lunge_speed := 0.0
export var staggers := false
export var xp_reward := 1

enum { IDLE, WANDER, CHASE, ATTACK }

var knockback := Vector2.ZERO
var velocity := Vector2.ZERO
var state := IDLE
var dead := false
var current_anim := ""
var cooldown := 0.0

onready var animation_tree: AnimationTree = $AnimationTree
onready var animation_state = animation_tree.get("parameters/playback")
onready var sprite: AnimatedSprite = $AnimatedSprite
onready var stats = $Stats
onready var player_detection_zone = $PlayerDetectionZone
onready var hurtbox = $Hurtbox
onready var soft_collision = $SoftCollision
onready var wander_controller = $WanderController
onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready() -> void:
	state = pick_random_state([IDLE, WANDER])
	if Game.get_difficulty() == Game.INSANE:
		stats.max_health *= INSANE_HEALTH_SCALE
		stats.health = stats.max_health

func _physics_process(delta: float) -> void:
	if dead:
		return

	if receives_knockback:
		knockback = knockback.move_toward(Vector2.ZERO, friction * delta)
		knockback = move_and_slide(knockback)

	if cooldown > 0.0:
		cooldown -= delta

	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			seek_player()
			if wander_controller.get_time_left() == 0:
				update_wander()
		WANDER:
			seek_player()
			if wander_controller.get_time_left() == 0:
				update_wander()
			accelerate_towards_point(wander_controller.target_position, delta)
			if global_position.distance_to(wander_controller.target_position) <= wander_target_range:
				state = IDLE
		CHASE:
			var player = player_detection_zone.player
			if player == null:
				state = IDLE
			elif global_position.distance_to(player.global_position) > attack_range:
				accelerate_towards_point(player.global_position, delta)
			elif cooldown <= 0.0:
				start_attack(player)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
				_face(player.global_position.x - global_position.x)
		ATTACK:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	velocity += soft_collision.get_push_vector() * delta * SOFT_PUSH_FORCE

	velocity = move_and_slide(velocity)
	if state != ATTACK:
		var run_speed := RUN_STOP_SPEED if current_anim == "run" else RUN_START_SPEED
		_play("run" if velocity.length() > run_speed else "idle")

func accelerate_towards_point(point: Vector2, delta: float) -> void:
	var direction := global_position.direction_to(point)
	velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	_face(velocity.x)

func _face(x: float) -> void:
	if abs(x) > FLIP_DEADZONE:
		sprite.flip_h = x < 0

func start_attack(player: Node2D) -> void:
	state = ATTACK
	velocity = Vector2.ZERO
	sprite.flip_h = player.global_position.x < global_position.x
	_play("attack")

func lunge() -> void:
	var player = player_detection_zone.player
	if dead or player == null:
		return
	velocity = global_position.direction_to(player.global_position) * lunge_speed

func attack_animation_finished() -> void:
	if dead:
		return
	cooldown = attack_cooldown
	state = CHASE

func update_wander() -> void:
	state = pick_random_state([IDLE, WANDER])
	wander_controller.start_wander_timer(rand_range(1, 3))

func seek_player() -> void:
	if player_detection_zone.can_see_player():
		state = CHASE

func pick_random_state(state_list: Array) -> int:
	state_list.shuffle()
	return state_list.pop_front()

func die() -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO
	sprite.modulate = Color.white
	hitbox_collision.set_deferred("disabled", true)
	if Checkpoint.lifesteal:
		PlayerStats.health += LIFESTEAL_HEAL
	if Checkpoint.add_xp(xp_reward):
		Game.popup_label(global_position + LEVEL_UP_OFFSET, "Level Up!", LEVEL_UP_COLOR)
	_play("defeat")
	var burst = DeathBurst.instance()
	get_tree().current_scene.add_child(burst)
	burst.global_position = sprite.global_position
	burst.reset_physics_interpolation()
	Game.shake(0.4)

func _play(anim_name: String) -> void:
	if current_anim == anim_name:
		return
	current_anim = anim_name
	animation_state.travel(anim_name)

func _on_Hurtbox_area_entered(area: Area2D) -> void:
	if dead:
		return
	stats.health -= area.damage
	if receives_knockback and area.get("knockback_vector") != null:
		knockback = area.knockback_vector * KNOCKBACK_FORCE
	hurtbox.create_hit_effect()
	Game.flash(sprite)
	Game.hitstop(0.05)
	Game.shake(0.25)
	if staggers and state == ATTACK:
		cancel_attack()

func cancel_attack() -> void:
	velocity = Vector2.ZERO
	sprite.modulate = Color.white
	hitbox_collision.set_deferred("disabled", true)
	cooldown = attack_cooldown
	state = CHASE

func _on_Stats_no_health() -> void:
	die()

func ending_scene() -> void:
	pass
