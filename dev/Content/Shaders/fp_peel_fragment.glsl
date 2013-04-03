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

int CalculateDCoC(float fd, float z);
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
	if (gl_FragCoord.z - frontDepth < 0.004) {
		discard;
	}

	float currentDepth = getRealZ(gl_FragCoord.z);
	float focusDepth = getRealZ(textureRect(DepthTex, vec2(focusX, focusY)).r);
	if(currentDepth < focusDepth)
	{
		int DCoC = CalculateDCoC(focusDepth, currentDepth);
		if(DCoC > ClearCoc){
			gl_FragColor = vec4(DCoC* 0.1, 0.25, 0.75,0);
//			return;
//			discard;
		}
	}

	// Shade all the fragments behind the z-buffer
	vec4 color = ShadeFragment();
	gl_FragColor = /*vec4(1.0, 1.0, 0, color.a); //*/vec4(color.rgb , color.a);
}
