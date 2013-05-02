#extension GL_ARB_texture_rectangle : enable
#extension GL_EXT_gpu_shader4 : enable

uniform samplerRECT scene;
uniform samplerRECT scene2;
uniform samplerRECT CocAndDepthMap;
//uniform samplerRECT CocMap;

uniform float width;
uniform float height;
uniform float FocusX;
uniform float FocusY;

uniform float currentLayer;

#define maxCoc 11
#define halfCoc 5

#define Klayers 23
#define ZNum 26
#define ZOFFSET 2
float CalculateDepthFromCoC(float focus_z, int coc);

void main()
{
	float focusDepth=textureRect(CocAndDepthMap, vec2(FocusX, FocusY)).g;

	float z[ZNum];
	for(int i = 0; i < Klayers; ++i)
	{
		z[i + ZOFFSET] = 1.0 + (i + ZOFFSET) * 0.5;//CalculateDepthFromCoC(focusDepth, 11 - i);
	}
	z[0] = 0.0f;
	z[1] = 0.0f;
	z[Klayers - 2 + ZOFFSET] = 190.0f;
	z[Klayers - 1 + ZOFFSET] = 210.0f;
	z[Klayers + ZOFFSET] = 230.0f;

	vec4 L[Klayers];

	vec4 CocAndDepth = textureRect(CocAndDepthMap, gl_FragCoord.xy);
	vec4 currentColor = textureRect(scene, gl_FragCoord.xy);
	float currentDepth = CocAndDepth.g;

	vec4 currentColor2 = textureRect(scene2, gl_FragCoord.xy);
	float currentDepth2 = CocAndDepth.a;

	currentColor.a = 1.0f;
	currentColor2.a = 1.0f;

	vec4 visibleLayerResult = currentColor;
	vec4 occludedLayerResult = currentColor2;

	int i = currentLayer;
//	for(int i = 0; i < Klayers; ++i)
	{	
		if( currentDepth >= z[i - 2 + ZOFFSET] )
		{	
			if( currentDepth < z[i - 1 + ZOFFSET] )
			{
				visibleLayerResult.a = (currentDepth - z[i - 2 + ZOFFSET]) / (z[i - 1 + ZOFFSET] - z[i - 2 + ZOFFSET]);
			}
			else if( currentDepth < z[i + ZOFFSET])
			{
			}
			else if (currentDepth < z[i + 1 + ZOFFSET])
			{
				visibleLayerResult.a = (currentDepth - z[i + 1 + ZOFFSET]) / (z[i + ZOFFSET] - z[i + 1 + ZOFFSET]);
			}
			else
				visibleLayerResult.a = 0;
		}
		else
				visibleLayerResult.a = 0;

		if( currentDepth2 >= z[i - 2 + ZOFFSET] )
		{
			if( currentDepth2 < z[i - 1 + ZOFFSET] )
			{
				occludedLayerResult.a = (currentDepth2 - z[i - 2 + ZOFFSET]) / (z[i - 1 + ZOFFSET] - z[i - 2 + ZOFFSET]);
			}
			else if( currentDepth2 < z[i + ZOFFSET])
			{
			}
			else
			{
				occludedLayerResult.a = 0 ;
			}
		}
		else 
			occludedLayerResult.a = 0 ;

		if((visibleLayerResult.a > 0) || (occludedLayerResult.a > 0))
		{
			L[i].a = visibleLayerResult.a + occludedLayerResult.a - visibleLayerResult.a * occludedLayerResult.a;
			L[i].rgb = occludedLayerResult.rgb + (visibleLayerResult.rgb - occludedLayerResult.rgb) * visibleLayerResult.a / L[i].a;
		}
		else
		{
			L[i] = vec4(0, 0, 0, 0);
		}
	//	gl_FragColor = L[i];
	//	gl_FragColor = vec4(currentDepth2 / 200.0, 0, 1, 1);//L[i];
	//	gl_FragColor = currentColor;
		gl_FragColor = vec4(L[i].rgb * L[i].a, L[i].a);
	//	gl_FragColor = visibleLayerResult * visibleLayerResult.a;
	//	gl_FragColor = occludedLayerResult * occludedLayerResult.a;
	}

}