extends KinematicBody2D

var speed = 50
var motion = Vector2.ZERO

var player = null

func _physics_process(delta):
	
	motion = Vector2.ZERO
	
	if player: 
		motion = position.direction_to(player.position) * speed
		motion = move_and_slide(motion)
		
	if motion.x < 1: 
		$AnimatedSprite.flip_h = true
	elif motion.x > 1:
		$AnimatedSprite.flip_h = false
	
	print(motion)
func _on_vision_area_body_entered(body):
	player = body

func _on_vision_area_body_exited(body):
	player = null

