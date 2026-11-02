extends KinematicBody2D

var key_up = "ui_up"
var key_down = "ui_down"
var key_left = "ui_left"
var key_right = "ui_right"
var key_attack = "ui_accept"
var key_dash = "dash"

const acceleration = 900
const max_speed = 150
const friction = 1100
const dash_speed = 320
const dash_iframes = 0.25
const dash_cooldown_time = 0.5
const hurt_sound = preload("res://audio and videos/Hurt.wav")

enum {
	MOVE,
	DASH,
	ATTACK,
	DEFEAT
}

var state = MOVE
var velocity = Vector2.ZERO
var dash_vector = Vector2.DOWN
var dash_cooldown = 0.0
var current_anim = ""
var stats = PlayerStats
var blinking = false
var blink_time = 0.0

onready var animation_tree = $AnimationTree
onready var animation_state = animation_tree.get("parameters/playback")
onready var sword_hitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox

func _ready():
	randomize()
	stats.connect("no_health", self, "start_defeat")
	hurtbox.connect("invincibility_started", self, "_on_invincibility_started")
	hurtbox.connect("invincibility_ended", self, "_on_invincibility_ended")
	animation_tree.active = true
	sword_hitbox.knockback_vector = dash_vector

func _process(delta):
	if not blinking:
		return
	blink_time += delta
	modulate.a = 1.0 if int(blink_time / 0.08) % 2 == 0 else 0.35

func _physics_process(delta):
	if dash_cooldown > 0.0:
		dash_cooldown -= delta
	if stats.health <= 0 and state != DEFEAT:
		start_defeat()
	match state:
		MOVE:
			move_state(delta)
		DASH:
			dash_state(delta)
		ATTACK:
			attack_state(delta)
		DEFEAT:
			defeat_state(delta)

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength(key_right) - Input.get_action_strength(key_left)
	input_vector.y = Input.get_action_strength(key_down) - Input.get_action_strength(key_up)
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		dash_vector = input_vector
		sword_hitbox.knockback_vector = input_vector
		animation_tree.set("parameters/idle/blend_position", input_vector)
		animation_tree.set("parameters/run/blend_position", input_vector)
		animation_tree.set("parameters/attack/blend_position", input_vector)
		animation_tree.set("parameters/dash/blend_position", input_vector)
		animation_tree.set("parameters/defeat/blend_position", input_vector)
		_play("run")
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
	else:
		_play("idle")
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move()

	if state == DEFEAT:
		return

	if Input.is_action_just_pressed(key_dash) and dash_cooldown <= 0.0:
		start_dash()

	if Input.is_action_just_pressed(key_attack):
		state = ATTACK

func start_dash():
	dash_vector = dash_vector.normalized()
	if dash_vector == Vector2.ZERO:
		dash_vector = Vector2.DOWN
	state = DASH
	dash_cooldown = dash_cooldown_time
	if not hurtbox.invincible:
		hurtbox.start_invicibility(dash_iframes)

func dash_state(_delta):
	velocity = dash_vector.normalized() * dash_speed
	_play("dash")
	move()

func attack_state(_delta):
	velocity = Vector2.ZERO
	_play("attack")

func start_defeat():
	if state == DEFEAT:
		return
	state = DEFEAT
	velocity = Vector2.ZERO
	blinking = false
	modulate.a = 1.0
	_play("defeat")

func defeat_state(_delta):
	velocity = Vector2.ZERO

func move():
	velocity = move_and_slide(velocity)

func _play(anim_name):
	if current_anim == anim_name:
		return
	current_anim = anim_name
	animation_state.travel(anim_name)

func dash_animation_finished():
	if state == DEFEAT:
		return
	velocity = velocity * 0.8
	state = MOVE

func attack_animation_finished():
	if state == DEFEAT:
		return
	state = MOVE

func defeat_animation_finished():
	get_tree().reload_current_scene()
	stats.health = stats.max_health

func _on_Hurtbox_area_entered(_area):
	if state == DEFEAT or hurtbox.invincible:
		return
	stats.health -= 1
	hurtbox.start_invicibility(1)
	hurtbox.create_hit_effect()
	_play_once(hurt_sound)

func _play_once(stream):
	var sfx = AudioStreamPlayer.new()
	sfx.stream = stream
	add_child(sfx)
	sfx.play()
	sfx.connect("finished", sfx, "queue_free")

func _on_invincibility_started():
	blinking = true
	blink_time = 0.0

func _on_invincibility_ended():
	blinking = false
	modulate.a = 1.0

func set_active(active):
	velocity = Vector2.ZERO
	_play("idle")
	set_physics_process(active)
	set_process(active)
	set_process_input(active)
