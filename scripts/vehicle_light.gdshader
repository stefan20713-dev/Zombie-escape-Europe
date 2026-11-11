shader_type canvas_item;
uniform float workshop = 0.0;
varying float height_y;
varying vec4 drawn_color;
void vertex() {
	height_y = VERTEX.y;
	drawn_color = COLOR;
}
void fragment() {
	vec4 paint = texture(TEXTURE, UV) * drawn_color;
	float upper = 1.0 - smoothstep(-36.0, 40.0, height_y);
	vec3 outdoor = mix(vec3(0.90, 0.95, 0.98), vec3(1.02, 1.01, 0.97), upper);
	vec3 indoor = mix(vec3(0.83, 0.88, 0.91), vec3(1.08, 1.00, 0.88), upper);
	paint.rgb *= mix(outdoor, indoor, workshop);
	COLOR = paint;
}
