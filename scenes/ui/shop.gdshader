shader_type canvas_item;

void fragment() {
	vec2 uv = UV;
	vec3 top_color = vec3(0.3, 0.5, 0.9);    // Light blue
	vec3 bottom_color = vec3(0.1, 0.2, 0.5); // Dark blue
	vec3 color = mix(bottom_color, top_color, uv.y);
	COLOR = vec4(color, 1.0);
}