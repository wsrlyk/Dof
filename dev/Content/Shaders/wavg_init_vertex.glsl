//--------------------------------------------------------------------------------------
// Order Independent Transparency with Average Color
//
// Author: Louis Bavoil
// Email: sdkfeedback@nvidia.com
//
// Copyright (c) NVIDIA Corporation. All rights reserved.
//--------------------------------------------------------------------------------------

vec3 ShadeVertex();
//varying vec2 uv;
void main(void)
{
	gl_Position = ftransform();
	gl_TexCoord[0].xyz = ShadeVertex();
//	uv = vec2(gl_MultiTexCoord0);
}
