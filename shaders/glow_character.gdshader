shader_type canvas_item;
uniform sampler2D n;
uniform float intensity = 0.0;
uniform float  speed = 1.0;

void fragment(){
	vec4 tx = texture(TEXTURE, UV);
	vec4 noise = texture(n, UV - TIME / (1.0 + speed));
	COLOR.a = clamp(tx.r * noise.r * intensity, 0.0, 1.0);
	COLOR.a = pow(COLOR.a, 2);
}
//custom_defines = ""