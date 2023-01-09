extends KinematicBody2D

const acceleration = 25
const max_speed = 200
const friction = 80

var motion = Vector2()

func _physics_process(delta):
	var input = Vector2() #right == 1,0  left  == -1, 0  x == 1,0  y == 0,1
	input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input = input.normalized()
	
	if input != Vector2.ZERO:
		if input.x == 1:
			$AnimatedSprite.flip_h = false
			$AnimatedSprite.play("side_run")
		elif input.x == -1: 
			$AnimatedSprite.flip_h = true
			$AnimatedSprite.play("side_run")
		elif input.y == 1:
			$AnimatedSprite.play("side_run") #down
		elif input.y == -1:
			$AnimatedSprite.play("side_run") # up
			
		motion += input * acceleration * delta
		motion = motion.clamped(max_speed * delta)
		
	else:
		$AnimatedSprite.play("idle")
		motion = motion.move_toward(Vector2.ZERO, friction * delta)

	move_and_collide(motion)
	#print(input)
