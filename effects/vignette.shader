shader_type canvas_item;

uniform vec4 tint : hint_color = vec4(0.06, 0.03, 0.02, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.6;
uniform float inner : hint_range(0.0, 1.5) = 0.55;
uniform float outer : hint_range(0.0, 1.5) = 1.3;

void fragment() {
	float d = length((UV - 0.5) * vec2(1.0, 0.75)) * 2.0;
	COLOR = vec4(tint.rgb, smoothstep(inner, outer, d) * strength);
}
