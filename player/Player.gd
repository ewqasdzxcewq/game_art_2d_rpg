extends KinematicBody2D

const ACCELERATION := 900.0
const MAX_SPEED := 150.0
const FRICTION := 1100.0
const DASH_SPEED := 320.0
const DASH_IFRAMES := 0.25
const DASH_COOLDOWN_TIME := 0.5
const DASH_UPGRADE_SCALE := 0.75
const ACTION_TIMEOUT := 0.6
const HURT_IFRAMES := 1.0
const HURT_KNOCKBACK := 180.0
const BLINK_INTERVAL := 0.08
const DUST_MIN_SPEED := 40.0
const AFTERIMAGE_INTERVAL := 0.035
const AFTERIMAGE_COLOR := Color(0.55, 0.8, 1.0, 0.55)
const GOURD_CHARGES := 3
const GOURD_HEAL := 4
const GOURD_TIME := 0.6
const HEAL_TINT := Color(0.5, 1.0, 0.55)
const HEAL_LABEL_COLOR := Color(0.45, 1.0, 0.5)
const HEAL_LABEL_OFFSET := Vector2(-8, -28)
const HurtSound = preload("res://audio and videos/Hurt.wav")
const BLEND_PATHS := [
	"parameters/idle/blend_position",
	"parameters/run/blend_position",
	"parameters/attack/blend_position",
	"parameters/dash/blend_position",
	"parameters/defeat/blend_position",
]

enum { MOVE, DASH, ATTACK, DEFEAT, HEAL }

export var use_checkpoint := true

var state := MOVE
var gourd := GOURD_CHARGES
var heal_time := 0.0
var heal_tween: SceneTreeTween
var velocity := Vector2.ZERO
var dash_vector := Vector2.DOWN
var dash_cooldown := 0.0
var action_time := 0.0
var current_anim := ""
var stats = PlayerStats
var blinking := false
var blink_time := 0.0
var afterimage_time := 0.0

onready var sprite: AnimatedSprite = $AnimatedSprite
onready var run_dust: CPUParticles2D = $RunDust
onready var animation_tree: AnimationTree = $AnimationTree
onready var animation_state = animation_tree.get("parameters/playback")
onready var sword_hitbox = $HitboxPivot/SwordHitbox
onready var sword_damage: int = sword_hitbox.damage
onready var hurtbox = $Hurtbox

func _enter_tree() -> void:
	if use_checkpoint and Checkpoint.last_position != null:
		global_position = Checkpoint.last_position

func _ready() -> void:
	stats.health = stats.max_health
	stats.connect("no_health", self, "start_defeat")
	hurtbox.connect("invincibility_started", self, "_on_invincibility_started")
	hurtbox.connect("invincibility_ended", self, "_on_invincibility_ended")
	animation_tree.active = true
	_face(dash_vector)
	reset_physics_interpolation()
	apply_upgrades()

func _process(delta: float) -> void:
	if not blinking:
		return
	blink_time += delta
	modulate.a = 1.0 if int(blink_time / BLINK_INTERVAL) % 2 == 0 else 0.35

func _physics_process(delta: float) -> void:
	if dash_cooldown > 0.0:
		dash_cooldown -= delta
	match state:
		MOVE:
			move_state(delta)
		DASH:
			dash_state(delta)
		ATTACK:
			attack_state(delta)
		HEAL:
			heal_state(delta)
		DEFEAT:
			velocity = Vector2.ZERO
	run_dust.emitting = state == DASH or (state == MOVE and velocity.length() > DUST_MIN_SPEED)

func move_state(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	if input_vector != Vector2.ZERO:
		if input_vector != dash_vector:
			_face(input_vector)
		_play("run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		_play("idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move()

	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		start_dash()
	elif Input.is_action_just_pressed("ui_accept"):
		state = ATTACK
		action_time = ACTION_TIMEOUT
	elif Input.is_action_just_pressed("heal") and gourd > 0 and stats.health < stats.max_health:
		state = HEAL
		heal_time = GOURD_TIME
		_play("idle")
		heal_tween = sprite.create_tween().set_loops(2)
		heal_tween.tween_property(sprite, "modulate", HEAL_TINT, GOURD_TIME / 4.0)
		heal_tween.tween_property(sprite, "modulate", Color.white, GOURD_TIME / 4.0)

func _face(direction: Vector2) -> void:
	dash_vector = direction
	sword_hitbox.knockback_vector = direction
	for path in BLEND_PATHS:
		animation_tree.set(path, direction)

func start_dash() -> void:
	state = DASH
	action_time = ACTION_TIMEOUT
	dash_cooldown = DASH_COOLDOWN_TIME * pow(DASH_UPGRADE_SCALE, Checkpoint.dash_upgrades)
	afterimage_time = 0.0
	if not hurtbox.invincible:
		hurtbox.start_invincibility(DASH_IFRAMES)

func dash_state(delta: float) -> void:
	velocity = dash_vector * DASH_SPEED
	_play("dash")
	move()
	afterimage_time -= delta
	if afterimage_time <= 0.0:
		afterimage_time = AFTERIMAGE_INTERVAL
		_spawn_afterimage()
	action_time -= delta
	if action_time <= 0.0:
		dash_animation_finished()

func _spawn_afterimage() -> void:
	var ghost := Sprite.new()
	ghost.texture = sprite.frames.get_frame(sprite.animation, sprite.frame)
	ghost.centered = sprite.centered
	ghost.offset = sprite.offset
	ghost.flip_h = sprite.flip_h
	ghost.modulate = AFTERIMAGE_COLOR
	get_parent().add_child(ghost)
	ghost.global_transform = sprite.global_transform
	ghost.reset_physics_interpolation()
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost, "queue_free")

func attack_state(delta: float) -> void:
	velocity = Vector2.ZERO
	_play("attack")
	action_time -= delta
	if action_time > 0.0:
		return
	sword_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	attack_animation_finished()

func heal_state(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move()
	heal_time -= delta
	if heal_time > 0.0:
		return
	gourd -= 1
	var previous: int = stats.health
	stats.health += GOURD_HEAL
	_stop_heal()
	Game.flash(sprite)
	Game.popup_label(global_position + HEAL_LABEL_OFFSET, "+%d" % (stats.health - previous), HEAL_LABEL_COLOR)
	_update_gourd()

func _stop_heal() -> void:
	if heal_tween:
		heal_tween.kill()
	sprite.modulate = Color.white
	state = MOVE

func apply_upgrades() -> void:
	sword_hitbox.damage = sword_damage + Checkpoint.damage_upgrades
	refill_gourd()

func refill_gourd() -> void:
	gourd = GOURD_CHARGES + Checkpoint.gourd_upgrades
	_update_gourd()

func _update_gourd() -> void:
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "gourd_ui", "set_gourd", gourd)

func start_defeat() -> void:
	if state == DEFEAT:
		return
	state = DEFEAT
	velocity = Vector2.ZERO
	blinking = false
	modulate.a = 1.0
	_play("defeat")

func move() -> void:
	velocity = move_and_slide(velocity)

func _play(anim_name: String) -> void:
	if current_anim == anim_name:
		return
	current_anim = anim_name
	animation_state.travel(anim_name)

func dash_animation_finished() -> void:
	if state == DEFEAT:
		return
	velocity *= 0.8
	state = MOVE

func attack_animation_finished() -> void:
	if state == DEFEAT:
		return
	state = MOVE

func defeat_animation_finished() -> void:
	Game.reload_scene()

func _on_Hurtbox_area_entered(area: Area2D) -> void:
	if state == DEFEAT or hurtbox.invincible:
		return
	if state == HEAL:
		_stop_heal()
	stats.health -= area.damage
	hurtbox.start_invincibility(HURT_IFRAMES)
	hurtbox.create_hit_effect()
	Game.play_sfx(HurtSound)
	Game.flash(sprite, 0.25)
	Game.hitstop(0.08)
	Game.shake(0.55)
	if state == MOVE:
		velocity = area.global_position.direction_to(global_position) * HURT_KNOCKBACK

func _on_invincibility_started() -> void:
	blinking = true
	blink_time = 0.0

func _on_invincibility_ended() -> void:
	blinking = false
	modulate.a = 1.0

func set_active(active: bool) -> void:
	velocity = Vector2.ZERO
	run_dust.emitting = false
	_play("idle")
	set_physics_process(active)
	set_process(active)
	set_process_input(active)
