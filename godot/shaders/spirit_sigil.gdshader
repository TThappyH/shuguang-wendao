shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;

uniform vec4 inner_color : source_color = vec4(0.28, 0.92, 0.82, 1.0);
uniform float pulse_speed = 1.2;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float radius = length(uv) * 2.0;
	float ring_a = 1.0 - smoothstep(0.02, 0.055, abs(radius - 0.72));
	float ring_b = 1.0 - smoothstep(0.018, 0.045, abs(radius - 0.42));
	float spokes = pow(abs(sin(atan(uv.y, uv.x) * 4.0)), 22.0) * smoothstep(0.18, 0.72, radius);
	float pulse = 0.62 + sin(TIME * pulse_speed) * 0.18;
	ALBEDO = inner_color.rgb;
	EMISSION = inner_color.rgb * 2.2;
	ALPHA = (ring_a + ring_b * 0.65 + spokes * 0.24) * pulse;
}
