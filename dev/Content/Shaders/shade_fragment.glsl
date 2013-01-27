//--------------------------------------------------------------------------------------
// Order Independent Transparency Fragment Shader
//
// Author: Louis Bavoil
// Email: sdkfeedback@nvidia.com
//
// Copyright (c) NVIDIA Corporation. All rights reserved.
//--------------------------------------------------------------------------------------

uniform float Alpha;
varying vec2 uv;
varying vec3 normal;
uniform sampler2D srcTexture;

#define COLOR_FREQ 30.0
#define ALPHA_FREQ 30.0

#if 1
vec4 ShadeFragment()
{
	vec4 color;

	vec3 n = normalize(normal);
	float nDotL = max(0.0, dot(n, normalize(gl_LightSource[0].position.xyz)));//gl_LightSource[0].position.xyz));
    float nDotH = max(0.0, dot(normal, vec3(gl_LightSource[0].halfVector)));
    float power = (nDotL == 0.0) ? 0.0 : pow(nDotH, gl_FrontMaterial.shininess);
    
    vec4 ambient = gl_FrontLightProduct[0].ambient;
    vec4 diffuse = gl_FrontLightProduct[0].diffuse;// * nDotL;
    vec4 specular = gl_FrontLightProduct[0].specular * power;
    vec4 lightColor = gl_FrontLightModelProduct.sceneColor + ambient + diffuse + specular;

	color = lightColor * vec4(texture2D(srcTexture, uv).rgb, 1);
//	color.rgb *= diffuse;
	return color;
}
#else
vec4 ShadeFragment()
{
	vec4 color;
	color.rgb = vec3(.4,.85,.0);
	color.a = Alpha;
	return color;
}
#endif
