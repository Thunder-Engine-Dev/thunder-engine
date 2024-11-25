shader_type canvas_item;

uniform bool mixing = false;

// https://godotengine.org/qa/53831/using-hsv-values-in-shaders-instead-of-rgb
vec4 hsv_to_rgb(float h, float s, float v, float a){
    //based on
    //https://stackoverflow.com/questions/51203917/math-behind-hsv-to-rgb-conversion-of-colors
    // So it needs values from 0 to 1
    float r;
    float g;
    float b;

    float i = floor(h*6.0);
    float f = h*6.0 -i;
    float p = v*(1.0-s);
    float q = v*(1.0-f*s);
    float t = v* (1.0-(1.0-f)*s);

    int cond = int(i)%6;

    if (cond == 0){
        r = v; g = t; b = p;
    }
    else if (cond == 1){
        r = q; g = v; b = p;
    }
    else if (cond == 2){
        r = p; g = v; b = t;
    }
    else if (cond == 3){
        r = p; g = q; b = v;
    }
    else if (cond == 4){
        r = t; g = p; b = v;
    }
    else if (cond == 5){
        r = v; g = p; b = q;
    }
    else {
        // THIS SHOULD NEVER HAPPEN
        r = 0.0; g = 0.0; b = 0.0;
    }
    return vec4(r,g,b,a);
    return vec4(0.5,1.0,0.0,1.0);
}

void fragment() {
  if (mixing) {
    //float s = float(abs(int(TIME * 20.0f) % 5)) / 4.0f;
    // vec4 f_color = texture(TEXTURE,UV) * texture(pallet,vec2(s,1)) * vec4(2.5,2.5,2.5,2.5);
    vec4 col_a = texture(TEXTURE, UV) + vec4(0.3, 0.3, 0.3, 0);
    // vec4 col_b = texture(pallet, vec2(s, 1)) * vec4(1.3, 1.3, 1.3, 0);
    vec4 col_b = hsv_to_rgb(TIME * 1.0f, 1, 1, 1) * vec4(1.3, 1.3, 1.3, 0);
    vec4 f_color;
    if (int(TIME * 20.0f) % 2 == 0) {
      f_color = col_a * col_b;
    } else {
      f_color = col_a * vec4(0.7, 0.7, 0.7, 0) * col_b;
    }
    f_color.a = col_a.a;
    COLOR = f_color;
  }

}
