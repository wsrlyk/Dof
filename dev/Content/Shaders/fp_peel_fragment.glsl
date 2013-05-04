//--------------------------------------------------------------------------------------
// Order Independent Transparency with Depth Peeling
//
// Author: Louis Bavoil
// Email: sdkfeedback@nvidia.com
//
// Copyright (c) NVIDIA Corporation. All rights reserved.
//--------------------------------------------------------------------------------------
uniform samplerRECT DepthTex;
uniform float focusX;
uniform float focusY;
float ClearCoc;
vec4 ShadeFragment();

float CalculateDCoC(float fd, float z);
float getRealZ(float z_b);
void main(void)
{
//gl_FragColor = vec4(getRealZ(textureRect(DepthTex, gl_FragCoord.xy).r) / 200);
//gl_FragColor = vec4(textureRect(DepthTex, gl_FragCoord.xy).r);

//return;
	// Bit-exact comparison between FP32 z-buffer and fragment depth
	float frontDepth = textureRect(DepthTex, gl_FragCoord.xy).r;
	if (gl_FragCoord.z <= frontDepth) {
		discard;
	}
	//if (gl_FragCoord.z - frontDepth < 0.004) {
	//	discard;
	//}

	float currentRealDepth = getRealZ(gl_FragCoord.z);
	float frontRealDepth = getRealZ(frontDepth);
	float focusDepth = getRealZ(textureRect(DepthTex, vec2(focusX, focusY)).r);
	if((frontRealDepth - focusDepth) * (currentRealDepth - focusDepth) >0
	 && abs(int(CalculateDCoC(focusDepth, currentRealDepth)) - int(CalculateDCoC(focusDepth, frontRealDepth))) <= 1)
		discard;

	// beautiworld		cut = 1;
	// keting				cut = 0;

	// Shade all the fragments behind the z-buffer
	vec4 color = ShadeFragment();
	gl_FragColor = /*vec4(1.0, 1.0, 0, color.a); //*/vec4(color.rgb , color.a);
}
