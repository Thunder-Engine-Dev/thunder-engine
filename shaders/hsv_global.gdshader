// 类似 Photoshop 中的 HSV 调整效果
shader_type canvas_item;

uniform float hue: hint_range(-1.0,1.0) = 0.0;
uniform float saturation: hint_range(-1.0,1.0) = 0.0;
uniform float value: hint_range(-1.0,1.0) = 0.0;

vec3 rgb_to_hsv(vec3 c) {
	// 转换
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz),
                 vec4(c.gb, K.xy),
                 step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r),
                 vec4(c.r, p.yzx),
                 step(p.x, c.r));
	float n = min(q.w, q.y);
    float d = q.x - n;
    float e = 1.0e-10;
	
    vec3 hsv = vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),
                d / (q.x + e),
                q.x);
	
	// 调整 Hue
	hsv.x += hue;
	hsv.x = mod(hsv.x, 1.0);
	
	// 调整 Saturation
	float light = (n + hsv.z)/2.0;
	float satl = d / (2.0 * mix(light, 1.0 - light, step(0.5, light)) + e);
	
	float sat_bool = step(saturation, 0.0);
	float a = mix(1.0 - saturation, satl, step(satl + saturation, 1.0));
	float alpha = mix(1.0/(a + e) - 1.0, 1.0 + saturation, sat_bool);
	
	d = hsv.z - light;
	q.x = alpha * d + mix(q.x, light, sat_bool);
	
	d = n - light;
	hsv.y = 1.0 - (alpha * d + mix(n, light, sat_bool))/(q.x + e);
	
	// 调整 Value
    hsv.z += value;
    hsv.z = clamp(hsv.z,0.0,1.0);
	
	return hsv;
}

vec3 hsv_to_rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	col.rgb = hsv_to_rgb(rgb_to_hsv(col.rgb));
	
	COLOR = col;
}
