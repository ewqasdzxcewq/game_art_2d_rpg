extends CanvasLayer

const FADE_TIME := 0.35
const MUSIC_FADE_TIME := 1.2
const SILENT_DB := -60.0
const HITSTOP_SCALE := 0.05
const SETTINGS_PATH := "user://settings.cfg"
const VOLUME_BUSES := ["Music", "SFX"]
const FPS_OPTIONS := [30, 60, 120, 144, 0]
const HitFlashShader = preload("res://effects/hit_flash.shader")
const UITheme = preload("res://UI/theme.tres")
const POPUP_RISE := 10.0
const DIFFICULTY_NAMES := ["Normal", "Hard", "Insane"]

enum { NORMAL, HARD, INSANE }

var _changing := false
var _hitstop_end_msec := 0
var _fade := ColorRect.new()
var _fade_tween := Tween.new()
var _music_tween := Tween.new()
var _music := AudioStreamPlayer.new()
var _music_out := AudioStreamPlayer.new()
var _settings := ConfigFile.new()

func _ready() -> void:
	randomize()
	pause_mode = PAUSE_MODE_PROCESS
	layer = 128
	_fade.color = Color.black
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_WIDE)
	add_child(_fade)
	add_child(_fade_tween)
	add_child(_music_tween)
	for player in [_music, _music_out]:
		player.bus = "Music"
		player.connect("finished", self, "_on_music_finished", [player])
		add_child(player)
	set_process(false)
	_load_settings()

func _process(_delta: float) -> void:
	if OS.get_ticks_msec() < _hitstop_end_msec:
		return
	Engine.time_scale = 1.0
	set_process(false)

func change_scene(path: String) -> void:
	if _changing:
		return
	_changing = true
	_fade_to(1.0)
	yield(_fade_tween, "tween_all_completed")
	get_tree().paused = false
	_hitstop_end_msec = 0
	Engine.time_scale = 1.0
	get_tree().change_scene(path)
	_fade_to(0.0)
	yield(_fade_tween, "tween_all_completed")
	_changing = false

func reload_scene() -> void:
	change_scene(get_tree().current_scene.filename)

func play_sfx(stream: AudioStream, volume_db := 0.0) -> void:
	if stream == null:
		return
	var sfx := AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	sfx.bus = "SFX"
	add_child(sfx)
	sfx.connect("finished", sfx, "queue_free")
	sfx.play()

func play_music(stream: AudioStream) -> void:
	if stream == null or (_music.stream == stream and _music.playing):
		return
	var previous := _music
	_music = _music_out
	_music_out = previous
	_music.stream = stream
	_music.volume_db = SILENT_DB
	_music.play()
	_music_tween.remove_all()
	_music_tween.interpolate_property(_music, "volume_db", SILENT_DB, 0.0, MUSIC_FADE_TIME, Tween.TRANS_SINE, Tween.EASE_OUT)
	_music_tween.interpolate_property(_music_out, "volume_db", _music_out.volume_db, SILENT_DB, MUSIC_FADE_TIME)
	_music_tween.interpolate_callback(_music_out, MUSIC_FADE_TIME, "stop")
	_music_tween.start()

func stop_music() -> void:
	_music_tween.remove_all()
	_music_tween.interpolate_property(_music, "volume_db", _music.volume_db, SILENT_DB, FADE_TIME)
	_music_tween.interpolate_callback(_music, FADE_TIME, "stop")
	_music_tween.start()
	_music_out.stop()

func hitstop(duration: float) -> void:
	_hitstop_end_msec = int(max(_hitstop_end_msec, OS.get_ticks_msec() + duration * 1000.0))
	Engine.time_scale = HITSTOP_SCALE
	set_process(true)

func shake(amount: float) -> void:
	var strength := get_shake_strength()
	if strength <= 0.0:
		return
	get_tree().call_group("camera", "shake", amount * strength)

func flash(item: CanvasItem, duration := 0.2) -> void:
	var material := item.material as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		material.shader = HitFlashShader
		item.material = material
	item.create_tween().tween_property(material, "shader_param/flash", 0.0, duration).from(1.0)

func popup_label(world_position: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.theme = UITheme
	label.text = text
	label.add_color_override("font_color", color)
	add_child(label)
	var start: Vector2 = get_viewport().get_canvas_transform().xform(world_position)
	label.rect_position = start
	var tween := label.create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.2).from(0.0)
	tween.parallel().tween_property(label, "rect_position:y", start.y - POPUP_RISE, 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(label, "queue_free")

func get_bus_volume(bus_name: String) -> float:
	return float(_settings.get_value("audio", bus_name, 1.0))

func set_bus_volume(bus_name: String, linear: float) -> void:
	_apply_bus_volume(bus_name, linear)
	_save_setting("audio", bus_name, linear)

func get_shake_strength() -> float:
	return float(_settings.get_value("video", "shake", 1.0))

func set_shake_strength(value: float) -> void:
	_save_setting("video", "shake", value)

func get_difficulty() -> int:
	return int(_settings.get_value("game", "difficulty", NORMAL))

func set_difficulty(value: int) -> void:
	_save_setting("game", "difficulty", value)

func get_best_score() -> int:
	return int(_settings.get_value("endless", "best_score", 0))

func set_best_score(value: int) -> void:
	_save_setting("endless", "best_score", value)

func get_max_fps() -> int:
	return int(_settings.get_value("video", "max_fps", 60 if OS.has_touchscreen_ui_hint() else 0))

func set_max_fps(fps: int) -> void:
	Engine.target_fps = fps
	_save_setting("video", "max_fps", fps)

func _save_setting(section: String, key: String, value) -> void:
	_settings.set_value(section, key, value)
	_settings.save(SETTINGS_PATH)

func _apply_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, linear <= 0.0)
	AudioServer.set_bus_volume_db(index, linear2db(max(linear, 0.0001)))

func _load_settings() -> void:
	_settings.load(SETTINGS_PATH)
	for bus_name in VOLUME_BUSES:
		_apply_bus_volume(bus_name, get_bus_volume(bus_name))
	Engine.target_fps = get_max_fps()

func _fade_to(alpha: float) -> void:
	_fade_tween.remove_all()
	_fade_tween.interpolate_property(_fade, "modulate:a", _fade.modulate.a, alpha, FADE_TIME)
	_fade_tween.start()

func _on_music_finished(player: AudioStreamPlayer) -> void:
	if player == _music:
		player.play()
