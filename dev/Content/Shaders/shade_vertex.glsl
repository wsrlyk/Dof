//--------------------------------------------------------------------------------------
// Order Independent Transparency Vertex Shader
//
// Author: Louis Bavoil
// Email: sdkfeedback@nvidia.com
//
// Copyright (c) NVIDIA Corporation. All rights reserved.
//--------------------------------------------------------------------------------------
varying vec2 uv;
varying vec3 normal;
vec3 ShadeVertex()
{
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	normal = normalize(gl_NormalMatrix * gl_Normal);
	float diffuse = abs(normalize(gl_NormalMatrix * gl_Normal).z);
	uv = vec2(gl_MultiTexCoord0);
	return vec3(gl_Vertex.xy, diffuse);
}
