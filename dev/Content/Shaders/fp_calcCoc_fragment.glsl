//--------------------------------------------------------------------------------------
// Order Independent Transparency with Depth Peeling
//
// Author: Louis Bavoil
// Email: sdkfeedback@nvidia.com
//
// Copyright (c) NVIDIA Corporation. All rights reserved.
//--------------------------------------------------------------------------------------
uniform float focusX;
uniform float focusY;
uniform samplerRECT DepthTex;

float MaxOutputDCoC;

int CalculateDCoC(float fd, float z);
float getRealZ(float z_b);
void main(void)
{
	float frontDepth = getRealZ(textureRect(DepthTex, gl_FragCoord.xy).r);
	float focusDepth = getRealZ(textureRect(DepthTex, vec2(focusX, focusY)).r);

	int DCoC = CalculateDCoC(focusDepth, frontDepth);
	gl_FragData[0] = vec4(1.0 * DCoC, frontDepth, 0, 1.0);
//	gl_FragData[1] = vec4(focusDepth);
//	gl_FragData[1] = vec4(frontDepth);
}
