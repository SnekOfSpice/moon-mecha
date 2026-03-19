shader_type canvas_item;

uniform sampler2D gradient;
uniform float brightness_amp = 1.0;
uniform vec3 color_amp = vec3(1.0);
uniform float intensity = 1.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec4 tex_color = texture(SCREEN_TEXTURE, UV);
	float brightness = (
		tex_color.r * color_amp.r +
		tex_color.g * color_amp.g +
		tex_color.b * color_amp.b) / 3.0;
	brightness *= brightness_amp;
	vec4 mapped_color = texture(gradient, vec2(brightness, 0));
    COLOR.rgb = mix(tex_color.rgb, mapped_color.rgb, intensity);
	COLOR.a = tex_color.a;
}