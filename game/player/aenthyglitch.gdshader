
// https://www.shadertoy.com/view/MdffD7
// Fork of FMS_Cat's VCR distortion shader

shader_type canvas_item;

// TODO: Add uniforms for tape crease discoloration and image jiggle

uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap, repeat_disable;


group_uniforms HSV_ADJUST;
uniform float hue: hint_range(-0.5, 0.5, 0.01) = 0.0;
uniform float saturation: hint_range(-1.0, 1.0, 0.01) = 0.0;
uniform float value: hint_range(-1.0, 1.0, 0.01) = 0.0;
// https://upload.wikimedia.org/wikipedia/commons/d/d8/Exposure_program_chart.gif
uniform float exposure: hint_range(0.0, 1.0, 0.01) = 0.5;

group_uniforms vhs_settings;
uniform vec2 vhs_resolution = vec2(320.0, 240.0);

uniform int samples = 2;
uniform float crease_noise: hint_range(0.0, 2.0, 0.1) = 1.0;
uniform float crease_opacity: hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float filter_intensity: hint_range(0.0, 1.0, 0.1) = 0.1;

group_uniforms tape_crease;
uniform float tape_crease_smear: hint_range(0.0, 2.0, 0.1) = 0.2;
uniform float tape_crease_intensity: hint_range(0.0, 1.0, 0.1) = 0.2;
uniform float tape_crease_jitter: hint_range(0.0, 1.0, 0.01) = 0.10;
uniform float tape_crease_speed: hint_range(-2.0, 2.0, 0.1) = 0.5;
uniform float tape_crease_discoloration: hint_range(0.0, 2.0, 0.1) = 1.0;
uniform bool tape_wave = false;

group_uniforms color_fuzz;
uniform float color_offset_multiplier: hint_range(0.0, 0.1) =  0.004;
uniform float black_offset_multiplier: hint_range(0.0, 0.1) = 0.1;
uniform float color_offset_x: hint_range(-0.1, 0.1) = 0.005;
uniform float color_offset_y: hint_range(-0.1, 0.1) = 0.005;
uniform float blur_amount: hint_range(0.0, 3.0, 0.1);

group_uniforms bottom_border;
uniform float bottom_border_thickness: hint_range(0.0,32.0, 0.1) = 6.0;
uniform float bottom_border_jitter: hint_range(0.0, 24.0, 0.5) = 6.0;

group_uniforms noise;
uniform float noise_intensity: hint_range(0.0, 1.0, 0.1) = 0.1;
uniform sampler2D noise_texture: filter_linear_mipmap, repeat_enable;

#define F_STOP_SQUARE 1.0
#define MIN_FLOAT 1.17549435e-38
#define MAX_FLOAT 3.402823466e+38
#define EPSILON 0.00001


bool nearly_equal(float a, float b) {
	float absA = abs(a);
	float absB = abs(b);
	float diff = abs(a - b);

	if (abs(a - b) < EPSILON) { // shortcut, handles infinities
		return true;
	} else if (a == 0.0 || b == 0.0 || (absA + absB < MIN_FLOAT)) {
		// a or b is zero or both are extremely close to it
		// relative error is less meaningful here
		return diff < (EPSILON * MIN_FLOAT);
	} else { // use relative error
		return diff / min((absA + absB), MAX_FLOAT) < EPSILON;
	}
}

float get_hue(vec3 rgb) {
	float minimum = min(min(rgb.r, rgb.g), rgb.b);
	float maximum = max(max(rgb.r, rgb.g), rgb.b);
	float delta = maximum - minimum;

	if (nearly_equal(delta, 0.0)) {
		return 0.0;
	}

	float ret;
	if (nearly_equal(rgb.r, maximum)) {
		ret = (rgb.g - rgb.b) / delta; // between yellow & magenta
	} else if (nearly_equal(rgb.g, maximum)) {
		ret = 2.0 + (rgb.b - rgb.r) / delta; // between cyan & yellow
	} else {
		ret = 4.0 + (rgb.r - rgb.g) / delta;// between magenta & cyan
	}

	ret /= 6.0;
	if (ret < 0.0) {
		ret += 1.0;
	}

	return ret;
}

float get_saturation(vec3 rgb) {
	float minimum = min(min(rgb.r, rgb.g), rgb.b);
	float maximum = max(max(rgb.r, rgb.g), rgb.b);
	float delta = maximum - minimum;
	return abs(maximum - 0.0) < EPSILON ? 0.0 : delta / maximum;
}

float get_value(vec3 rgb) {
	return max(max(rgb.r, rgb.g), rgb.b);
}

vec3 rgb2hsv(vec3 rgb) {
	return vec3(get_hue(rgb), get_saturation(rgb), get_value(rgb));
}

vec3 hsv2rgb(vec3 hsv) {
	vec3 rgb;
	int i;
	float f, p, q, t;

	if (nearly_equal(hsv.y, 0.0)) {
		rgb.r = rgb.g = rgb.b = hsv.z;
		return rgb;
	}

	hsv.x *= 6.0;
	hsv.x = mod(hsv.x, 6.0);
	i = int(floor(hsv.x));

	f = hsv.x - float(i);
	p = hsv.z * (1.0 - hsv.y);
	q = hsv.z * (1.0 - hsv.y * f);
	t = hsv.z * (1.0 - hsv.y * (1.0 - f));

	switch (i) {
		case 0: // Red is the dominant color
			rgb.r = hsv.z;
			rgb.g = t;
			rgb.b = p;
			break;
		case 1: // Green is the dominant color
			rgb.r = q;
			rgb.g = hsv.z;
			rgb.b = p;
			break;
		case 2:
			rgb.r = p;
			rgb.g = hsv.z;
			rgb.b = t;
			break;
		case 3: // Blue is the dominant color
			rgb.r = p;
			rgb.g = q;
			rgb.b = hsv.z;
			break;
		case 4:
			rgb.r = t;
			rgb.g = p;
			rgb.b = hsv.z;
			break;
		default: // (5) Red is the dominant color
			rgb.r = hsv.z;
			rgb.g = p;
			rgb.b = q;
			break;
	}

	return rgb;
}

vec3 rgb_to_yuv(vec3 rgb) {
	const mat3 RGB_TO_YUV = mat3(
		vec3(0.299, 0.587, 0.114),
		vec3(-0.14713, -0.28886, 0.436),
		vec3(.615, -0.51499, -0.10001)
		);
	return rgb * RGB_TO_YUV;
}
vec3 yuv_to_rgb(vec3 yuv) {
	const mat3 YUV_TO_RGB = mat3(
		vec3(1.0, 0.0, 1.13983),
		vec3(1.0, -0.39465, -0.58060),
		vec3(1.0, 2.03211, 0.0)
		);
	return clamp(yuv * YUV_TO_RGB, vec3(0.0), vec3(1.0));
}


float v2random(vec2 uv) {
	return texture(noise_texture, mod(uv, vec2(1.0))).x;
}

mat2 rotate2D(float t) {
	return mat2(vec2(cos(t), sin(t)), vec2(-sin(t), cos(t)));
}

vec3 rgb2yiq(vec3 rgb) {
	return mat3(vec3(0.299, 0.596, 0.211), vec3(0.587, -0.274, -0.523), vec3(0.114, -0.322, 0.312)) * rgb;
}

vec3 yiq2rgb(vec3 yiq) {
	return mat3(vec3(1.0, 1.0, 1.0), vec3(0.956, -0.272, -1.106), vec3(0.621, -0.647, 1.703)) * yiq;
}

group_uniforms first_colorspace_filter;
uniform bool f_hsv2rgb = false;
uniform bool f_rgb2hsv = false;
uniform bool f_yiq2rgb = false;
uniform bool f_rgb2yiq = true;
uniform bool f_yuv2rgb = false;
uniform bool f_rgb2yuv = false;

group_uniforms second_colorspace_filter;
uniform bool s_hsv2rgb = false;
uniform bool s_rgb2hsv = false;
uniform bool s_yiq2rgb = false;
uniform bool s_rgb2yiq = false;
uniform bool s_yuv2rgb = true;
uniform bool s_rgb2yuv = false;

vec3 f_transform_color_sapce(vec3 base){
	bool multiply = false;
	if(f_hsv2rgb){
		base = hsv2rgb(base);
		multiply = true;
	} 
	if (f_rgb2hsv){
		if(multiply) {base *= rgb2hsv(base);}
		else base = rgb2hsv(base);
		multiply = true;
	} 
	if (f_yiq2rgb){
		if(multiply) {base *= yiq2rgb(base);}
		else base = yiq2rgb(base);
		multiply = true;
	} 
	if (f_rgb2yiq){
		if(multiply) {base *= rgb2yiq(base);}
		else base = rgb2yiq(base);
		multiply = true;
	} 
	if (f_yuv2rgb){
		if(multiply) {base *= yuv_to_rgb(base);}
		else base = yuv_to_rgb(base);
		multiply = true;
	} 
	if (f_rgb2yuv){
		if(multiply) {base *= rgb_to_yuv(base);}
		else base = rgb_to_yuv(base);
		multiply = true;
	} 
	return base;
}

vec3 s_transform_color_space(vec3 base){
	bool multiply = false;
	if (s_hsv2rgb){
		base = hsv2rgb(base);
		multiply = true;
	} 
	if (s_rgb2hsv){
		if(multiply) {base *= rgb2hsv(base);}
		else base = rgb2hsv(base);
		multiply = true;
	} 
	if (s_yiq2rgb){
		if(multiply) {base *= yiq2rgb(base);}
		else base = yiq2rgb(base);
		multiply = true;
	} 
	if (s_rgb2yiq){
		if(multiply) {base *= rgb2yiq(base);}
		else base = rgb2yiq(base);
		multiply = true;
	} 
	if (s_yuv2rgb){
		if(multiply) {base *= yuv_to_rgb(base);}
		else base = yuv_to_rgb(base);
		multiply = true;
	} 
	if (s_rgb2yuv){
		if(multiply) {base *= rgb_to_yuv(base);}
		else base = rgb_to_yuv(base);
		multiply = true;
	} 
	return base;
}


vec3 vhx_tex_2D(sampler2D tex, vec2 uv, float rot) {
	vec3 yiq = vec3(0.0);
	for (int i = 0; i < samples; i++) {
		yiq += f_transform_color_sapce((texture(tex, uv - vec2(float(i), 0.0) / vhs_resolution).xyz)) * vec2(float(i), float(samples - 1 - i)).yxx / float(samples - 1) / float(samples) * 2.0;
	}
	if (rot != 0.0) {
		yiq.yz *= rotate2D(rot * tape_crease_discoloration);
	}
	return s_transform_color_space(yiq);
}

float noise(vec2 uv, float offset) {
	return (fract(sin(dot(uv * offset, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 2.0;
}

void fragment() {
	vec2 uvn = SCREEN_UV;//UV;
	float black_offset = noise(vec2(floor(UV.y * 487.0), fract(UV.y * 487.0)), TIME + 69.420) * (black_offset_multiplier * 0.01);
	
	vec3 col = textureLod(screen_texture, SCREEN_UV + vec2(black_offset, 0.), 0.0).rgb;

	//col = yuv_to_rgb(vec3(yuv1.b, yuv2.r, yuv3.r));
	//col = yuv_to_rgb(vec3(vhs_tex.r, vhs_tex.g, yuv3.r));
	//col = vhs_tex;//yuv_to_rgb(vhs_tex);
	
	
	//vec3 col = vec3(0.0, 0.0, 0.0);

	// Tape wave.
	if(tape_wave){
		uvn.x += (v2random(vec2(uvn.y / 10.0, TIME / 10.0) / 1.0) - 0.5) / vhs_resolution.x * 1.0;
		uvn.x += (v2random(vec2(uvn.y, TIME * 10.0)) - 0.5) / vhs_resolution.x * 1.0;
	}

	// tape crease
	float tc_phase = smoothstep(0.15, 0.15, sin(uvn.y * 8.0 - (TIME * tape_crease_speed + tape_crease_jitter * v2random(TIME * vec2(0.67, 0.59))) * PI * 1.2));
	float tc_noise = smoothstep(0.1, 0.1, v2random(vec2(uvn.y * 4.77, TIME)));
	float tc = 0.15 * tc_noise;
	uvn.x = uvn.x - tc / vhs_resolution.x * 4.0 * tape_crease_smear;

	// switching noise
	float sn_phase = smoothstep(1.0 - bottom_border_thickness / vhs_resolution.y, 1.0, uvn.y);
	uvn.x += sn_phase * (v2random(vec2(UV.y * 100.0, TIME * 10.0)) - 0.5) / vhs_resolution.x * bottom_border_jitter;

	// fetch
	
	col = vhx_tex_2D(screen_texture, uvn, 0.001);// tc * 0.2 + sn_phase * 2.0);
	//color fuzz
	float x_offset = color_offset_x + noise(vec2(floor(UV.y * 487.0), fract(UV.y * 487.0)), TIME) * color_offset_multiplier;
	float y_offset = color_offset_y + noise(vec2(floor(UV.y * 487.0), fract(UV.y * 487.0)), TIME) * color_offset_multiplier;
	
	vec3 color2 = vhx_tex_2D(screen_texture, SCREEN_UV + vec2(x_offset, y_offset), blur_amount);
	vec3 color3 = vhx_tex_2D(screen_texture, SCREEN_UV - vec2(x_offset + 0.01, y_offset), blur_amount);
	vec3 yuv1 = rgb_to_yuv(col);
	vec3 yuv2 = rgb_to_yuv(color2);
	vec3 yuv3 = rgb_to_yuv(color3);
	
	col = yuv_to_rgb(vec3(yuv1.r, yuv2.g, yuv3.b));
	//col = yuv_to_rgb(yuv1);

	// crease noise
	float cn = tc_noise * crease_noise * (0.7 * tc_phase * tape_crease_intensity + 0.3);
	if (0.29 < cn) {
		vec2 V = vec2(0.0, crease_opacity);
		vec2 uvt = (uvn + V.yx * v2random(vec2(uvn.y, TIME))) * vec2(0.1, 1.0);
		float n0 = v2random(uvt);
		float n1 = v2random(uvt + V.yx / vhs_resolution.x);
		if (n1 < n0) {
			col = mix(col, 2.0 * V.yyy, pow(n0, 10.0));
		}
	}

	// ac beat
	col *= 1.0 + 0.1 * smoothstep(0.4, 0.6, v2random(vec2(0.0, 0.1 * (UV.y + TIME * 0.2)) / 10.0));

	// color noise
	col *= 1.0 - noise_intensity * 0.5 + noise_intensity * texture(noise_texture, mod(uvn * vec2(1.0, 1.0) + TIME * vec2(5.97, 4.45), vec2(1.0))).xyz;
	col = clamp(col, 0.0, 1.0);

	// yiq
	
	
	
	//col = rgb2yiq(col);
	//col = vec3(0.9, 1.1, 1.5) * col + vec3(0.1, -0.1, 0.0) * filter_intensity;
	//col = yiq2rgb(col);
	//col = yuv_to_rgb(yuv1);
	
	// HSV + exposure
	vec3 HSV = rgb2hsv(col);

	HSV.x = mod(HSV.x + hue, 1.0);
	HSV.y = clamp(HSV.y + saturation, 0.0, 1.0);
	HSV.z = clamp(HSV.z + value, 0.0, 1.0);

	COLOR.rgb = hsv2rgb(HSV);

	// Exposure
	COLOR.rgb *= log2(F_STOP_SQUARE / exposure);
}