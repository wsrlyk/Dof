#extension GL_ARB_texture_rectangle : enable
#extension GL_EXT_gpu_shader4 : enable
uniform vec3 BackgroundColor;

uniform samplerRECT scene;
uniform samplerRECT scene2;
uniform samplerRECT CocAndDepthMap;
//uniform samplerRECT CocMap;

uniform float width;
uniform float height;
uniform float focusX;
uniform float focusY;

#define maxCoc 11
#define halfCoc 5
void main(void)
{

	vec4 CocAndDepth = textureRect(CocAndDepthMap, gl_FragCoord.xy);
	vec4 currentColor = textureRect(scene, gl_FragCoord.xy);
	float currentDepth = CocAndDepth.g;
	float focusDepth=textureRect(CocAndDepthMap, vec2(focusX, focusY)).g;
	float currentFloatCoc = CocAndDepth.r;
	int currentCoc = int(currentFloatCoc);
//	gl_FragColor = textureRect(scene2, gl_FragCoord.xy);
//	gl_FragColor =  vec4(currentCoc / 11.0, 0.25, 0.75,0);//*/FocusBlur(MaxOutputDCoC, fd, 15);//textureRect(scene, gl_FragCoord.xy);//smoothBlur(vec2(width,height), fd*MaxDistance, 100);
//	  gl_FragColor =  vec4(currentDepth / 10, currentDepth / 50, currentDepth / 50,1);														// œ‘ æ…Ó∂»Õº
//	return;

	int currentIsFore = currentDepth - focusDepth < 0 ? 1: 0;
	float tmpX, tmpY;
	float mean, zeta = 0;
	float depth;
	vec2 tmpXY;
	vec2 tmpXYx2;

	int tempCoc;
	float tempDepth;
	int tempCoc2;
	float tempDepth2;
	int tempIsFore;
	int largerCoc;

	vec4 colorSumFore[maxCoc + 1];
	vec4 colorSumBack[maxCoc + 1];
	int pointAmountFore[maxCoc + 1];
	int pointAmountBack[maxCoc + 1];
	
	int updateFore[maxCoc + 1];
	int updateBack[maxCoc + 1];

	vec4 colorResultFore[maxCoc + 1];
	vec4 colorResultBack[maxCoc + 1];

	for(int i = 0; i <= maxCoc; ++i)
	{
		colorSumFore[i] = vec4(0, 0, 0, 0);
		colorSumBack[i] = vec4(0, 0, 0, 0);
		pointAmountFore[i] = 0;
		pointAmountBack[i] = 0;
		
		updateFore[i] = 0;
		updateBack[i] = 0;

		colorResultFore[i] = vec4(0, 0, 0, 0);
		colorResultBack[i] = vec4(0, 0, 0, 0);
	}
	for(int col=-halfCoc; col <= halfCoc; col+=1)
	{
		for(int row=-halfCoc; row <= halfCoc; row+=1)
		{
			tmpXY = vec2(gl_FragCoord.x+col, gl_FragCoord.y + row);
			CocAndDepth = textureRect(CocAndDepthMap, tmpXY);
			tempCoc = int(CocAndDepth.r);
			tempDepth = CocAndDepth.g;
			tempCoc2 = int(CocAndDepth.b);
			tempDepth2 = CocAndDepth.a;

			tmpXYx2 = vec2(abs(col) * 2, abs(row) * 2);
			vec4 color4 = textureRect(scene, tmpXY);
			vec4 color42 = textureRect(scene2, tmpXY);

			tempIsFore = tempDepth - focusDepth < 0 ? 1: 0;

			largerCoc = tempCoc;
			// add temp to current if they are similar
			if(abs(tempCoc - currentCoc) == 2 &&  tempIsFore == currentIsFore)
			{
				if(currentCoc> tmpXYx2.x && currentCoc > tmpXYx2.y)
				{
					largerCoc = currentCoc;
					if(currentIsFore)
					{
						colorSumFore[currentCoc] += color4;
						pointAmountFore[currentCoc] += 1;
					}
					else
					{
						colorSumBack[currentCoc] += color4;
						pointAmountBack[currentCoc] += 1;
					}
				}
			}

			if(tempCoc > tmpXYx2.x && tempCoc > tmpXYx2.y)
			{
				if(tempIsFore)
				{
					colorSumFore[tempCoc] += color4;
					pointAmountFore[tempCoc] += 1;
				}
				else
				{
					colorSumBack[tempCoc] += color4;
					pointAmountBack[tempCoc] += 1;
				}
			}

			if(tempCoc2 != largerCoc && tempCoc2 > tmpXYx2.x && tempCoc2 > tmpXYx2.y)
			{
				if(tempDepth2 < focusDepth)
				{
					colorSumFore[tempCoc2] += color42;
					pointAmountFore[tempCoc2] += 1;
	//			updateFore[tempCoc] = -1;
				}
				else
				{
					colorSumBack[tempCoc2] += color42;
					pointAmountBack[tempCoc2] += 1;
		//			updateFore[tempCoc] = -1;
				}
			}

			//for(int i = 1; i <= maxCoc; i += 2)
			//{
			//	colorSumFore[i] += (color4 * updateFore[i]);
			//	pointAmountFore[i] += updateFore[i];
			//	colorSumBack[i] += (color4 * updateBack[i]);
			//	pointAmountBack[i] += updateBack[i];

			//	updateFore[i] = 0;
			//	updateBack[i] = 0;
			//}
		}
	}

	for(int i = 1; i <= maxCoc; i += 2)
	{
		colorResultFore[i].rgb = colorSumFore[i].rgb / max(1, pointAmountFore[i]);
		colorResultFore[i].a = clamp(pointAmountFore[i] / float(i * i), 0.0, 1.0);
		colorResultBack[i].rgb = colorSumBack[i].rgb / max(1, pointAmountBack[i]);
		colorResultBack[i].a = clamp(pointAmountBack[i] / float(i * i), 0.0, 1.0);
	}


	vec4 blendColor0;
	vec4 blendColor1 = colorResultBack[11];
	//vec4 blendColor1 = colorResultFore[9];
	//vec4 blendColor1 = colorResultBack[11];
	//	gl_FragColor = vec4(mix(vec3(1, 0,0), blendColor1.rgb,blendColor1.a), 1.0);
	//	if(blendColor1.a < 0.9999 && blendColor1.a > 0)
	//		gl_FragColor = vec4(1, 0, 0 ,1);
	//return;

	blendColor1.a =  blendColor1.a + colorResultBack[9].a - colorResultBack[9].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultBack[9].rgb, colorResultBack[9].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultBack[10].rgb - colorResultBack[11].rgb) * (0) / colorResultBack[11].a;
	blendColor1.a =  blendColor1.a + colorResultBack[7].a - colorResultBack[7].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultBack[7].rgb, colorResultBack[7].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultBack[10].rgb - colorResultBack[11].rgb) * (0) / colorResultBack[11].a;
	blendColor1.a =  blendColor1.a + colorResultBack[5].a - colorResultBack[5].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultBack[5].rgb, colorResultBack[5].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultBack[10].rgb - colorResultBack[11].rgb) * (0) / colorResultBack[11].a;
	blendColor1.a =  blendColor1.a + colorResultBack[3].a - colorResultBack[3].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultBack[3].rgb, colorResultBack[3].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultBack[10].rgb - colorResultBack[11].rgb) * (0) / colorResultBack[11].a;
	blendColor1.a =  blendColor1.a + colorResultBack[1].a - colorResultBack[1].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultBack[1].rgb, colorResultBack[1].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultBack[10].rgb - colorResultBack[11].rgb) * (0) / colorResultBack[11].a;

	blendColor1.a =  blendColor1.a + colorResultFore[1].a - colorResultFore[1].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[1].rgb, colorResultFore[1].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[3].a - colorResultFore[3].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[3].rgb, colorResultFore[3].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[5].a - colorResultFore[5].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[5].rgb, colorResultFore[5].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[7].a - colorResultFore[7].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[7].rgb, colorResultFore[7].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[9].a - colorResultFore[9].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[9].rgb, colorResultFore[9].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[11].a - colorResultFore[11].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[11].rgb, colorResultFore[11].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;


		gl_FragColor = vec4(blendColor1.rgb * blendColor1.a, 1.0);
		return;
//	if(blendColor1.a > 0)
		gl_FragColor = mix(textureRect(scene, gl_FragCoord.xy), blendColor1, blendColor1.a);

//		gl_FragColor = vec4(blendColor1.a, blendColor1.a, blendColor1.a, 1.0);
//	if(blendColor1.a >1)
//		gl_FragColor = vec4(1.0, 0, 0, 1);
//	gl_FragColor = vec4(pointAmountFore[10] / 100, colorResultFore[10].a, colorResultFore[10].a, blendColor1.a);
//	gl_FragColor = vec4((blendColor1.a + 0.0001) * 10000, 0, 0, blendColor1.a);
//	gl_FragColor = vec4(pointAmountFore[11] / 121.0, pointAmountFore[11] / 121.0, pointAmountFore[11] / 121.0, 1);
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultFore[9].a - colorResultFore[9].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultFore[9].rgb - blendColor0.rgb) * colorResultFore[9].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultFore[8].a - colorResultFore[8].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultFore[8].rgb - blendColor0.rgb) * colorResultFore[8].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultFore[7].a - colorResultFore[7].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultFore[7].rgb - blendColor0.rgb) * colorResultFore[7].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultFore[6].a - colorResultFore[6].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultFore[6].rgb - blendColor0.rgb) * colorResultFore[6].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultFore[5].a - colorResultFore[5].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultFore[5].rgb - blendColor0.rgb) * colorResultFore[5].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultFore[4].a - colorResultFore[4].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultFore[4].rgb - blendColor0.rgb) * colorResultFore[4].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultFore[3].a - colorResultFore[3].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultFore[3].rgb - blendColor0.rgb) * colorResultFore[3].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultFore[2].a - colorResultFore[2].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultFore[2].rgb - blendColor0.rgb) * colorResultFore[2].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultFore[1].a - colorResultFore[1].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultFore[1].rgb - blendColor0.rgb) * colorResultFore[1].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultFore[0].a - colorResultFore[0].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultFore[0].rgb - blendColor0.rgb) * colorResultFore[0].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultBack[1].a - colorResultBack[1].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultBack[1].rgb - blendColor0.rgb) * colorResultBack[1].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultBack[2].a - colorResultBack[2].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultBack[2].rgb - blendColor0.rgb) * colorResultBack[2].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultBack[3].a - colorResultBack[3].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultBack[3].rgb - blendColor0.rgb) * colorResultBack[3].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultBack[4].a - colorResultBack[4].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultBack[4].rgb - blendColor0.rgb) * colorResultBack[4].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultBack[5].a - colorResultBack[5].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultBack[5].rgb - blendColor0.rgb) * colorResultBack[5].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultBack[6].a - colorResultBack[6].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultBack[6].rgb - blendColor0.rgb) * colorResultBack[6].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultBack[7].a - colorResultBack[7].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultBack[7].rgb - blendColor0.rgb) * colorResultBack[7].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultBack[8].a - colorResultBack[8].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultBack[8].rgb - blendColor0.rgb) * colorResultBack[8].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultBack[9].a - colorResultBack[9].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultBack[9].rgb - blendColor0.rgb) * colorResultBack[9].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultBack[10].a - colorResultBack[10].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultBack[10].rgb - blendColor0.rgb) * colorResultBack[10].a / blendColor1.a;
	//blendColor0 = blendColor1;
	//blendColor1.a = blendColor0.a + colorResultBack[11].a - colorResultBack[11].a * blendColor0.a;
	//blendColor1.rgb = blendColor0.rgb + (colorResultBack[11].rgb - blendColor0.rgb) * colorResultBack[11].a / blendColor1.a;

//	gl_FragColor = blendColor1;
}