#version 300 es

layout(location = 0) in vec4 a_postion;
layout(location = 1) in vec2 textureIn;

out vec2 textureCoord;
void main(void)
{
    gl_Position = a_postion;
    textureCoord = textureIn;
}
