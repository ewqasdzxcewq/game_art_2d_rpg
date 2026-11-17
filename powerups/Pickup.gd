extends Area2D

const PickupSound = preload("res://audio and videos/Menu Select.wav")
const HeartTexture = preload("res://UI/player ui/HeartUIFull.png")
const BOB_HEIGHT := 3.0
const BOB_TIME := 0.8
const BREATHE_SCALE := 1.08
const BUBBLE_RADIUS := 10.0
const RIPPLE_SPREAD := 8.0
const RIPPLE_TIME := 1.2
const SHINE_COLOR := Color(1, 1, 1, 0.85)
const DROP_POINTS := [Vector2(0, -4.5), Vector2(-2.6, 0.5), Vector2(2.6, 0.5)]
const BLADE_POINTS := [Vector2(0, -6), Vector2(1.6, 1), Vector2(0, 2.5), Vector2(-1.6, 1)]
const CHEVRON_LEFT := [Vector2(-4, -3), Vector2(-1, 0), Vector2(-4, 3)]
const CHEVRON_RIGHT := [Vector2(0, -3), Vector2(3, 0), Vector2(0, 3)]
const LABEL_OFFSET := Vector2(-40, -48)
const KINDS := [
	{ "text": "Max Health +2", "color": Color(1, 0.35, 0.4) },
	{ "text": "Lifesteal", "color": Color(0.75, 0.3, 1) },
	{ "text": "Damage Up", "color": Color(1, 0.6, 0.2) },
	{ "text": "Gourd +1", "color": Color(0.4, 0.9, 0.5) },
	{ "text": "Swift Dash", "color": Color(0.4, 0.8, 1) },
]

enum { HEALTH, LIFESTEAL, DAMAGE, GOURD, DASH }

export(int, "Health Upgrade", "Lifesteal", "Damage Up", "Gourd +1", "Swift Dash") var kind := HEALTH

var ripple := 0.0

onready var bubble: Node2D = $Bubble
onready var glow: Light2D = $Glow

func _ready() -> void:
	if Checkpoint.collected.has(str(get_path())):
		queue_free()
		return
	glow.color = KINDS[kind].color
	bubble.connect("draw", self, "_draw_bubble")
	var bob := bubble.create_tween().set_loops()
	bob.tween_property(bubble, "position:y", bubble.position.y - BOB_HEIGHT, BOB_TIME).set_trans(Tween.TRANS_SINE)
	bob.parallel().tween_property(bubble, "scale", Vector2.ONE * BREATHE_SCALE, BOB_TIME).set_trans(Tween.TRANS_SINE)
	bob.tween_property(bubble, "position:y", bubble.position.y, BOB_TIME).set_trans(Tween.TRANS_SINE)
	bob.parallel().tween_property(bubble, "scale", Vector2.ONE, BOB_TIME).set_trans(Tween.TRANS_SINE)
	create_tween().set_loops().tween_method(self, "_set_ripple", 0.0, 1.0, RIPPLE_TIME)

func _set_ripple(value: float) -> void:
	ripple = value
	bubble.update()

func _draw_bubble() -> void:
	var color: Color = KINDS[kind].color
	var ring := color
	ring.a = (1.0 - ripple) * 0.6
	var fill := color
	fill.a = 0.25
	bubble.draw_arc(Vector2.ZERO, BUBBLE_RADIUS + ripple * RIPPLE_SPREAD, 0.0, TAU, 32, ring, 1.0, true)
	bubble.draw_circle(Vector2.ZERO, BUBBLE_RADIUS, fill)
	bubble.draw_arc(Vector2.ZERO, BUBBLE_RADIUS, 0.0, TAU, 32, color.lightened(0.4), 1.5, true)
	bubble.draw_arc(Vector2.ZERO, BUBBLE_RADIUS - 3.0, PI * 1.1, PI * 1.45, 8, SHINE_COLOR, 1.5, true)
	match kind:
		HEALTH:
			bubble.draw_texture(HeartTexture, (-HeartTexture.get_size() / 2.0).floor())
		LIFESTEAL:
			bubble.draw_circle(Vector2(0, 1.5), 3.0, color)
			bubble.draw_colored_polygon(DROP_POINTS, color)
		DAMAGE:
			bubble.draw_colored_polygon(BLADE_POINTS, color)
			bubble.draw_line(Vector2(-3, 2.5), Vector2(3, 2.5), color, 1.5)
			bubble.draw_line(Vector2(0, 2.5), Vector2(0, 5.5), color, 1.5)
		GOURD:
			bubble.draw_circle(Vector2(0, -2.5), 2.2, color)
			bubble.draw_circle(Vector2(0, 2), 3.2, color)
		DASH:
			bubble.draw_polyline(CHEVRON_LEFT, color, 1.5, true)
			bubble.draw_polyline(CHEVRON_RIGHT, color, 1.5, true)

func _on_Pickup_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	match kind:
		HEALTH:
			Checkpoint.health_upgrades += 1
		LIFESTEAL:
			Checkpoint.lifesteal = true
		DAMAGE:
			Checkpoint.damage_upgrades += 1
		GOURD:
			Checkpoint.gourd_upgrades += 1
		DASH:
			Checkpoint.dash_upgrades += 1
	Checkpoint.collect(str(get_path()))
	PlayerStats.health = PlayerStats.max_health
	body.apply_upgrades()
	Game.play_sfx(PickupSound)
	Game.shake(0.3)
	Game.popup_label(global_position + LABEL_OFFSET, KINDS[kind].text, KINDS[kind].color)
	queue_free()
