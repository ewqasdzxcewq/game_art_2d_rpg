extends YSort

var spawns := []

func _ready() -> void:
	add_to_group("mob_respawner")
	for mob in get_children():
		if Game.get_difficulty() == Game.NORMAL and mob.is_in_group("hard_only"):
			mob.queue_free()
			continue
		spawns.append({ "scene": load(mob.filename), "position": mob.position, "mob": mob })

func respawn() -> void:
	for spawn in spawns:
		if is_instance_valid(spawn.mob):
			continue
		var mob = spawn.scene.instance()
		mob.position = spawn.position
		add_child(mob)
		mob.reset_physics_interpolation()
		spawn.mob = mob
