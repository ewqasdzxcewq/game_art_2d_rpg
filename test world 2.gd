extends Node2D

func _enter_tree():
	if Checkpoint.last_position:
		$Middleground/Player.global_position = Checkpoint.last_position
