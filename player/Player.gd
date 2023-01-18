extends KinematicBody2D

var key_up = "ui_up"
var key_down = "ui_down"
var key_left = "ui_left"
var key_right = "ui_right"
var key_attack = "ui_accept"
var key_dash = "dash"

const acceleration = 600
const max_speed = 150
const friction = 800
const dash_speed = 200

enum {
	MOVE,
	DASH,
	ATTACK,
	DEFEAT
}

var state = MOVE
var velocity = Vector2.ZERO
var dash_vector = Vector2.DOWN
var stats = PlayerStats
var last_checkpoint: Area2D = null

onready var animation_player = $AnimationPlayer
onready var animation_tree = $AnimationTree
onready var animation_state = animation_tree.get("parameters/playback")
onready var sword_hitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox

func _ready():
	randomize()
	stats.connect("no_health", self, "defeat_state")
	animation_tree.active = true
	sword_hitbox.knockback_vector = dash_vector
	
func _physics_process(delta):
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
	input_vector += input_vector.normalized()

	if input_vector != Vector2.ZERO:
		dash_vector = input_vector
		sword_hitbox.knockback_vector = input_vector
		animation_tree.set("parameters/idle/blend_position", input_vector)
		animation_tree.set("parameters/run/blend_position", input_vector)
		animation_tree.set("parameters/attack/blend_position", input_vector)
		animation_tree.set("parameters/dash/blend_position", input_vector)
		animation_tree.set("parameters/defeat/blend_position", input_vector)
		animation_state.travel("run")
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
	else:
		animation_state.travel("idle")
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move()

	if Input.is_action_just_pressed(key_dash):
		state = DASH
		
	if Input.is_action_pressed(key_attack):
		state = ATTACK
	
	if PlayerStats.health <= 0:
		state = DEFEAT
	
func dash_state(_delta):
	velocity = dash_vector * dash_speed
	animation_state.travel("dash")
	move()
	
func attack_state(_delta):
	velocity = Vector2.ZERO
	animation_state.travel("attack")

func defeat_state(_delta):
	velocity = Vector2.ZERO
	animation_state.travel("defeat")
	
func move():
	velocity = move_and_slide(velocity)
	
func dash_animation_finished():
	velocity = velocity * 0.8
	state = MOVE

func attack_animation_finished():
	state = MOVE
	
func defeat_animation_finished():
	get_tree().reload_current_scene()
	stats.health = stats.max_health

func _on_Hurtbox_area_entered(_area):
	stats.health -= 1
	hurtbox.start_invicibility(1)
	hurtbox.create_hit_effect()
	
	print(stats.health)

func set_active(active):
	velocity = Vector2.ZERO
	animation_state.travel("idle")
	set_physics_process(active)
	set_process(active)
	set_process_input(active)
	
	

	
