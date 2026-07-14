shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 glow = tex.rgb + vec3(intensity) * 1.5;
	COLOR = vec4(glow, tex.a);
}
