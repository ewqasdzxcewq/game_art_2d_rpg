extends Node2D

const MiniDeviling = preload("res://mobs/mini poring/MiniDeviling.tscn")
const Marauder = preload("res://mobs/marauder/Maurader.tscn")
const ARENA_WIDTH := 60
const ARENA_HEIGHT := 40
const MAP_SEED := 7
const FLOOR_TILE := 0
const DECOR := [{ "tile": 1, "count": 9 }, { "tile": 2, "count": 8 }]
const DECOR_CHANCE := 0.035
const SPAWN_AREA := Rect2(64, 96, 832, 480)
const SPAWN_OFFSET := Vector2(240, 140)
const MIN_SPAWN_DISTANCE := 100.0
const SPAWN_TRIES := 8
const WORLD_LAYER := 1
const SPAWN_FADE_TIME := 0.4
const FIRST_WAVE_MOBS := 4
const MOBS_PER_WAVE := 2
const MAX_ALIVE := 12
const SPAWN_INTERVAL := 2.0
const SPAWN_INTERVAL_STEP := 0.15
const MIN_SPAWN_INTERVAL := 0.6
const WAVE_BREAK := 3.0
const MARAUDER_WAVE := 2
const MARAUDER_CHANCE_STEP := 0.08
const MAX_MARAUDER_CHANCE := 0.5
const HEALTH_STEP := 0.2
const SPEED_STEP := 0.05
const MAX_SPEED_SCALE := 1.6
const COOLDOWN_STEP := 0.05
const MIN_COOLDOWN_SCALE := 0.5
const DAMAGE_WAVES := 5
const TINT_STEP := 0.06
const MAX_TINT := 0.5
const MINI_POINTS := 10
const MARAUDER_POINTS := 30
const WAVE_BONUS := 50
const BANNER_FADE := 0.3
const BANNER_TIME := 1.5
const SCORE_COLOR := Color(1, 0.85, 0.4)
const POPUP_OFFSET := Vector2(-12, -40)

var wave := 0
var score := 0
var best := 0
var to_spawn := 0
var alive := 0
var game_over := false
var banner_tween: SceneTreeTween

onready var floor_map: TileMap = $Floor
onready var decor_map: TileMap = $Floor/Decor
onready var mobs: YSort = $Middleground/Mobs
onready var player = $Middleground/Player
onready var spawn_timer: Timer = $SpawnTimer
onready var score_label: Label = $CanvasLayer/Score
onready var banner: Label = $CanvasLayer/Banner

func _ready() -> void:
	best = Game.get_best_score()
	PlayerStats.connect("no_health", self, "_on_player_died")
	_paint_map()
	_next_wave()

func _exit_tree() -> void:
	if score > best:
		Game.set_best_score(score)

func _paint_map() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = MAP_SEED
	for x in ARENA_WIDTH:
		for y in ARENA_HEIGHT:
			floor_map.set_cell(x, y, FLOOR_TILE)
			if rng.randf() >= DECOR_CHANCE:
				continue
			var decor: Dictionary = DECOR[rng.randi() % DECOR.size()]
			decor_map.set_cell(x, y, decor.tile, false, false, false, Vector2(rng.randi() % decor.count, 0))

func _next_wave() -> void:
	if game_over:
		return
	wave += 1
	to_spawn = FIRST_WAVE_MOBS + (wave - 1) * MOBS_PER_WAVE
	spawn_timer.start(max(SPAWN_INTERVAL - (wave - 1) * SPAWN_INTERVAL_STEP, MIN_SPAWN_INTERVAL))
	_show_banner("Wave %d" % wave)
	_update_score()

func _on_SpawnTimer_timeout() -> void:
	if alive >= MAX_ALIVE or not _spawn_mob():
		return
	to_spawn -= 1
	if to_spawn == 0:
		spawn_timer.stop()

func _spawn_mob() -> bool:
	var spawn_position = _find_spawn_position()
	if spawn_position == null:
		return false
	var level := wave - 1
	var is_marauder := wave >= MARAUDER_WAVE and randf() < min(level * MARAUDER_CHANCE_STEP, MAX_MARAUDER_CHANCE)
	var mob = (Marauder if is_marauder else MiniDeviling).instance()
	var stats = mob.get_node("Stats")
	stats.max_health = int(ceil(stats.max_health * (1.0 + level * HEALTH_STEP)))
	mob.max_speed = int(mob.max_speed * min(1.0 + level * SPEED_STEP, MAX_SPEED_SCALE))
	mob.attack_cooldown *= max(1.0 - level * COOLDOWN_STEP, MIN_COOLDOWN_SCALE)
	mob.get_node("Hitbox").damage += level / DAMAGE_WAVES
	mob.xp_reward = 0
	var tint := 1.0 - min(level * TINT_STEP, MAX_TINT)
	mob.modulate = Color(1, tint, tint, 0)
	mob.position = spawn_position
	stats.connect("no_health", self, "_on_mob_killed", [mob, MARAUDER_POINTS if is_marauder else MINI_POINTS])
	mobs.add_child(mob)
	mob.reset_physics_interpolation()
	mob.create_tween().tween_property(mob, "modulate:a", 1.0, SPAWN_FADE_TIME)
	alive += 1
	return true

func _find_spawn_position():
	var space := get_world_2d().direct_space_state
	for _i in SPAWN_TRIES:
		var offset := Vector2(rand_range(-1, 1), rand_range(-1, 1)) * SPAWN_OFFSET
		var point: Vector2 = player.global_position + offset
		point.x = clamp(point.x, SPAWN_AREA.position.x, SPAWN_AREA.end.x)
		point.y = clamp(point.y, SPAWN_AREA.position.y, SPAWN_AREA.end.y)
		if point.distance_to(player.global_position) < MIN_SPAWN_DISTANCE:
			continue
		if space.intersect_point(point, 1, [], WORLD_LAYER).empty():
			return point
	return null

func _on_mob_killed(mob: Node2D, points: int) -> void:
	alive -= 1
	var gained := points * wave
	score += gained
	Game.popup_label(mob.global_position + POPUP_OFFSET, "+%d" % gained, SCORE_COLOR)
	_update_score()
	if to_spawn == 0 and alive == 0:
		_clear_wave()

func _clear_wave() -> void:
	if game_over:
		return
	score += WAVE_BONUS * wave
	_update_score()
	player.refill_gourd()
	_show_banner("Wave %d cleared!" % wave)
	get_tree().create_timer(WAVE_BREAK, false).connect("timeout", self, "_next_wave")

func _on_player_died() -> void:
	game_over = true
	spawn_timer.stop()
	_show_banner("Game Over\nScore %d" % score, true)

func _update_score() -> void:
	score_label.text = "Wave %d   Score %d   Best %d" % [wave, score, max(best, score)]

func _show_banner(text: String, stay := false) -> void:
	banner.text = text
	if banner_tween:
		banner_tween.kill()
	banner_tween = create_tween()
	banner_tween.tween_property(banner, "modulate:a", 1.0, BANNER_FADE).from(0.0)
	if stay:
		return
	banner_tween.tween_interval(BANNER_TIME)
	banner_tween.tween_property(banner, "modulate:a", 0.0, BANNER_FADE)
