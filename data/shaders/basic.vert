#version 460

#extension GL_GOOGLE_include_directive : enable

struct Material{
	vec4	  diffuse;
	vec4	  specular; // w is the Glossines factor
	float	  ior;	    // index of refraction
	float	  glossiness;
	int		  illum;
};

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec3 inColor;
layout(location = 3) in vec2 inUV;

layout(location = 0) out vec3 outPosition;
layout(location = 1) out vec3 outNormal;
layout(location = 2) out vec3 outColor;
layout(location = 3) out vec2 outUV;
layout(location = 4) out float outMat;
//layout(location = 5) out float matIdx;

struct ObjectData{
	mat4 model;
	//int materialIdx;
};

// Set 0 - Camera information
layout(set = 0, binding = 0) uniform CameraBuffer
{
	mat4 viewprojection;
} cameraData;

// Set 1 - Object info, matrices at the moment
layout(std140, set = 1, binding = 0) readonly buffer ObjectBuffer{
	ObjectData objects[];
}objectBuffer;

layout(push_constant) uniform constants
{
    layout(offset = 4) int matIdx;
}pushC;

void main()
{
	mat4 modelMatrix = objectBuffer.objects[gl_BaseInstance].model;
	//Material m = objectBuffer.objects[gl_BaseInstance].mat;
	mat4 transformationMatrix = cameraData.viewprojection * modelMatrix;
	gl_Position =  transformationMatrix * vec4(inPosition, 1.0);

	outPosition = vec3(modelMatrix * vec4(inPosition, 1.0)).xyz;
    outColor  	= inColor; // * m.diffuse.xyz;
	outNormal 	= vec3(vec4(inNormal, 1.0) * modelMatrix).xyz;
    outUV 		= inUV;
	outMat 		= float(pushC.matIdx) / 10;
	//matIdx 		= float(objectBuffer.objects[gl_BaseInstance].materialIdx) / 10.0f;
	//outMat 		= vec4(m.ior, m.glossiness, m.illum, 0);
}