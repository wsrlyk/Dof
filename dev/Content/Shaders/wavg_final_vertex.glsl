//--------------------------------------------------------------------------------------
// Order Independent Transparency with Average Color
//
// Author: Louis Bavoil
// Email: sdkfeedback@nvidia.com
//
// Copyright (c) NVIDIA Corporation. All rights reserved.
//--------------------------------------------------------------------------------------
varying vec2 uv;
void main(void)
{
     gl_Position = gl_ModelViewMatrix * gl_Vertex;
	uv = vec2(gl_MultiTexCoord0);
}
