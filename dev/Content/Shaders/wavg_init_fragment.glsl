//--------------------------------------------------------------------------------------
// Order Independent Transparency with Average Color
//
// Author: Louis Bavoil
// Email: sdkfeedback@nvidia.com
//
// Copyright (c) NVIDIA Corporation. All rights reserved.
//--------------------------------------------------------------------------------------

//#extension ARB_draw_buffers : require


vec4 ShadeFragment();
varying vec2 uv;

uniform sampler2D srcTexture;

void main(void)
{
	vec4 color = ShadeFragment();
//	gl_FragData[0] = vec4(color.rgb * color.a, color.a);
//	gl_FragData[0] = vec4(texture2DRect(srcTexture, uv).rgb * color.a, color.a);
gl_FragData[0] = color; //vec4(texture2D(srcTexture, gl_TexCoord[0].xy).rgb, 1);
	gl_FragData[1] = vec4(1.0);
}
