// gpt all the way
shader_type canvas_item;

uniform float radius : hint_range(0.0, 2.0) = 0.8;     // radius where the vignette reaches full strength
uniform float softness : hint_range(0.0, 1.0) = 0.25; // how soft the edge is
uniform float strength : hint_range(0.0, 1.0) = 0.0;  // runtime intensity, 0..1
uniform vec4 tint = vec4(1.0, 0.0, 0.0, 1.0); // color of the vignette

void fragment() {
    // SCREEN_UV gives normalized screen coords (0..1)
    vec2 uv = SCREEN_UV;
    vec2 center = vec2(0.5);
    float dist = distance(uv, center);

    // compute smoothstep with edge0 < edge1
    float inner = max(0.0, radius - softness);
    float v = smoothstep(inner, radius, dist); // 0 inside inner, 1 at/after radius

    // combine with strength and tint alpha
    float alpha = clamp(v * strength * tint.a, 0.0, 1.0);
    COLOR = vec4(tint.rgb, alpha);
}