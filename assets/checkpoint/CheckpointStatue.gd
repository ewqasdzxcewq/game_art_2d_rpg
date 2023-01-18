extends Area2D

func _ready():
	$AnimationPlayer.play("default")

func _on_CheckpointObject_body_entered(_body):
	PlayerStats.health = PlayerStats.max_health
	Checkpoint.last_position = global_position
	$AnimationPlayer.play("active")
