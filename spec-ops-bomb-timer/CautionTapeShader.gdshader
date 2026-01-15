shader_type canvas_item;

uniform float TexturePosition = 0.0; // 0..1 wrapping value
uniform float direction = 1.0;       // 1 = right, -1 = left

void fragment() {
    vec2 uv = UV + vec2(TexturePosition * direction, 0.0);
    uv = fract(uv);
    COLOR = texture(TEXTURE, uv);
}
