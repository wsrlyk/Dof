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
uniform samplerRECT DepthTex2;

float MaxOutputDCoC;

float CalculateDCoC(float fd, float z);
float getRealZ(float z_b);
void main(void)
{
	float frontDepth = getRealZ(textureRect(DepthTex, gl_FragCoord.xy).r);
	float focusDepth = getRealZ(textureRect(DepthTex, vec2(focusX, focusY)).r);

	float DCoC = CalculateDCoC(focusDepth, frontDepth);
	float frontDepth2 = getRealZ(textureRect(DepthTex2, gl_FragCoord.xy).r);

	float DCoC2 = CalculateDCoC(focusDepth, frontDepth2);
	gl_FragData[0] = vec4(DCoC, frontDepth, DCoC2, frontDepth2);
//	gl_FragData[1] = vec4(focusDepth);
//	gl_FragData[1] = vec4(frontDepth);
}
