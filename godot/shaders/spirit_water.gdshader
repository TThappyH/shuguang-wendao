shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.24, 0.65, 0.68, 0.72);
uniform vec4 deep_color : source_color = vec4(0.08, 0.32, 0.39, 0.84);
uniform vec4 foam_color : source_color = vec4(0.73, 0.92, 0.86, 1.0);
uniform float wave_scale = 2.4;
uniform float wave_speed = 0.32;

void fragment() {
	vec2 p = UV * 8.0 * wave_scale;
	float wave_a = sin(p.x + TIME * wave_speed * 3.0) * 0.5 + 0.5;
	float wave_b = sin(p.y * 1.37 - TIME * wave_speed * 2.1) * 0.5 + 0.5;
	float wave = wave_a * wave_b;
	ALBEDO = mix(deep_color.rgb, shallow_color.rgb, wave * 0.68 + 0.2);
	ROUGHNESS = 0.2;
	METALLIC = 0.08;
	ALPHA = mix(deep_color.a, shallow_color.a, wave);
	EMISSION = foam_color.rgb * pow(wave, 8.0) * 0.32;
}
