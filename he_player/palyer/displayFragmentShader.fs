#version 300 es
precision mediump float;
precision mediump int;

layout(location=0) out vec4 outColor;

in vec2 textureCoord;
uniform sampler2D tex_y;
uniform sampler2D tex_u;
uniform sampler2D tex_v;

void main(void)
{
    float y = texture(tex_y, textureCoord).r;
    float u = texture(tex_u, textureCoord).r - 0.5;
    float v = texture(tex_v, textureCoord).r - 0.5;

    float r = y + 1.402 * v;
    float g = y - 0.344 * u - 0.714 * v;
    float b = y + 1.772 * u;

    outColor = vec4(r, g,b, 1);
}
