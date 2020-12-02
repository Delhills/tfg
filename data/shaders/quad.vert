#version 450

layout (location = 0) in vec3 inPosition;
layout (location = 1) in vec3 inNormal;
layout (location = 2) in vec3 inColor;
layout (location = 3) in vec2 inUV;

layout (location = 0) out vec2 outUV;

layout(push_constant) uniform constants
{
	vec4 data;
	mat4 matrix;
}pushC;

void main()
{
	outUV = inUV;
	gl_Position = vec4( inPosition, 1.0 );
}