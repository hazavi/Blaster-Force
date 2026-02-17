shader_type canvas_item;

void fragment() {
	vec2 uv = UV;
	vec3 top_color = vec3(0.09, 0.09, 0.09);
	vec3 bottom_color = vec3(0, 0, 0);
	vec3 color = mix(bottom_color, top_color, uv.y);
	COLOR = vec4(color, 1.0);
}