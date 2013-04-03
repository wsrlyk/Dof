#extension GL_ARB_texture_rectangle : enable
#extension GL_EXT_gpu_shader4 : enable
uniform vec3 BackgroundColor;

uniform samplerRECT scene;
uniform samplerRECT scene2;
uniform samplerRECT CocAndDepthMap;
//uniform samplerRECT CocMap;

uniform float width;
uniform float height;
uniform float FocusX;
uniform float FocusY;

#define maxCoc 11
#define halfCoc 5
void main(void)
{

	vec4 CocAndDepth = textureRect(CocAndDepthMap, gl_FragCoord.xy);

	float currentDepth = CocAndDepth.a;
	float focusDepth=textureRect(CocAndDepthMap, vec2(FocusX, FocusY)).g;
	int currentCoc = int(CocAndDepth.b);

//	gl_FragColor =  vec4(currentCoc / 11.0, 0.25, 0.75,0);//*/FocusBlur(MaxOutputDCoC, fd, 15);//textureRect(scene, gl_FragCoord.xy);//smoothBlur(vec2(width,height), fd*MaxDistance, 100);
//	  gl_FragColor =  vec4(currentDepth / 50, currentDepth / 50, currentDepth / 50,1);														// œ‘ æ…Ó∂»Õº
//	return;


	float tmpX, tmpY;
	float mean, zeta = 0;
	float depth;
	vec2 tmpXY;

	int tempCoc;
	int tempDepth;

	vec4 colorSumFore[maxCoc + 1];
	vec4 colorSumBack[maxCoc + 1];
	int pointAmountFore[maxCoc + 1];
	int pointAmountBack[maxCoc + 1];

	vec4 colorResultFore[maxCoc + 1];
	vec4 colorResultBack[maxCoc + 1];

	for(int i = 0; i <= maxCoc; ++i)
	{
		colorSumFore[i] = vec4(0, 0, 0, 0);
		colorSumBack[i] = vec4(0, 0, 0, 0);
		pointAmountFore[i] = 0;
		pointAmountBack[i] = 0;
		colorResultFore[i] = vec4(0, 0, 0, 0);
		colorResultBack[i] = vec4(0, 0, 0, 0);
	}

	for(int col=-halfCoc; col <= halfCoc; col+=1)
	{
		for(int row=-halfCoc; row <= halfCoc; row+=1)
		{
			tmpX = clamp(gl_FragCoord.x+col,0.5,width - 0.5);
			tmpY = clamp(gl_FragCoord.y+row,0.5,height - 0.5);
			tmpXY= vec2(tmpX, tmpY);

			CocAndDepth = textureRect(CocAndDepthMap, tmpXY);
			tempCoc = int(CocAndDepth.r);
			tempDepth = int(CocAndDepth.g);

			int l = 1;
	//		if((abs(col) * 2>= tempCoc) || (abs(row) * 2 > tempCoc))
	//			l = 0;
			l = clamp(tempCoc - abs(col) * 2, 0, 1) *  clamp(tempCoc + 1 - abs(row) * 2, 0, 1);

			vec4 color4 = textureRect(scene, tmpXY);
			if(tempDepth <= focusDepth)
			{
			int k;
			k = abs(tempCoc - 0);
				k = (1 - clamp(k, 0, 1)) * l;
				colorSumFore[0] += k *color4;
				pointAmountFore[0] += k;
			k = abs(tempCoc - 1);
				k = (1 - clamp(k, 0, 1)) * l;
				colorSumFore[1] += k *color4;
				pointAmountFore[1] += k;
			k = abs(tempCoc - 2);
				k = (1 - clamp(k, 0, 1)) * l;
				colorSumFore[2] += k *color4;
				pointAmountFore[2] += k;
			k = abs(tempCoc - 3);
				k = (1 - clamp(k, 0, 1)) * l;
				colorSumFore[3] += k *color4;
				pointAmountFore[3] += k;
			k = abs(tempCoc - 4);
				k = (1 - clamp(k, 0, 1)) * l;
				colorSumFore[4] += k *color4;
				pointAmountFore[4] += k;
			k = abs(tempCoc - 5);
				k = (1 - clamp(k, 0, 1)) * l;
				colorSumFore[5] += k *color4;
				pointAmountFore[5] += k;
			k = abs(tempCoc - 6);
				k = (1 - clamp(k, 0, 1)) * l;
				colorSumFore[6] += k *color4;
				pointAmountFore[6] += k;
			k = abs(tempCoc - 7);
				k = (1 - clamp(k, 0, 1)) * l;
				colorSumFore[7] += k *color4;
				pointAmountFore[7] += k;
			k = abs(tempCoc - 8);
				k = (1 - clamp(k, 0, 1)) * l;
				colorSumFore[8] += k *color4;
				pointAmountFore[8] += k;
			k = abs(tempCoc - 9);
				k = (1 - clamp(k, 0, 1)) * l;
				colorSumFore[9] += k *color4;
				pointAmountFore[9] += k;
			k = abs(tempCoc - 10);
				k = (1 - clamp(k, 0, 1)) * l;
				colorSumFore[10] += k *color4;
				pointAmountFore[10] += k;
			k = abs(tempCoc - 11);
				k = (1 - clamp(k, 0, 1)) * l;
				colorSumFore[11] += k *color4;
				pointAmountFore[11] += k;

				// test
				//colorSumFore[0] = vec4(1, 0, 0, 1);
				//pointAmountFore[0] = 1;

			}
			else
			{
			int k;
			k = abs(0.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumBack[0] += k * l *color4;
				pointAmountBack[0] += k * l;
			k = abs(1.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumBack[1] += k * l *color4;
				pointAmountBack[1] += k * l;
			k = abs(2.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumBack[2] += k * l *color4;
				pointAmountBack[2] += k * l;
			k = abs(3.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumBack[3] += k * l *color4;
				pointAmountBack[3] += k * l;
			k = abs(4.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumBack[4] += k * l *color4;
				pointAmountBack[4] += k * l;
			k = abs(5.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumBack[5] += k * l *color4;
				pointAmountBack[5] += k * l;
			k = abs(6.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumBack[6] += k * l *color4;
				pointAmountBack[6] += k * l;
			k = abs(7.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumBack[7] += k * l *color4;
				pointAmountBack[7] += k * l;
			k = abs(8.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumBack[8] += k * l *color4;
				pointAmountBack[8] += k * l;
			k = abs(9.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumBack[9] += k * l *color4;
				pointAmountBack[9] += k * l;
			k = abs(10.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumBack[10] += k * l *color4;
				pointAmountBack[10] += k * l;
			k = abs(11.0 - tempCoc);
			k = 1.0 - (k / k);
				colorSumBack[11] += k * l *color4;
				pointAmountBack[11] += k * l;
			}
		}
	}

	colorResultFore[0].rgb = colorSumFore[0].rgb / max(1, pointAmountFore[0]);
	colorResultFore[0].a = pointAmountFore[0] / (1.0);
	colorResultFore[1].rgb = colorSumFore[1].rgb / max(1, pointAmountFore[1]);
	colorResultFore[1].a = pointAmountFore[1] / (1.0);
	colorResultFore[2].rgb = colorSumFore[2].rgb / max(1, pointAmountFore[2]);
	colorResultFore[2].a = pointAmountFore[2] / (2.0 * 2.0 - 1.0);
	colorResultFore[3].rgb = colorSumFore[3].rgb / max(1, pointAmountFore[3]);
	colorResultFore[3].a = pointAmountFore[3] / (3.0 * 3.0);
	colorResultFore[4].rgb = colorSumFore[4].rgb / max(1, pointAmountFore[4]);
	colorResultFore[4].a = pointAmountFore[4] / (4.0 * 4.0 - 1.0);
	colorResultFore[5].rgb = colorSumFore[5].rgb / max(1, pointAmountFore[5]);
	colorResultFore[5].a = pointAmountFore[5] / (5.0 * 5.0);
	colorResultFore[6].rgb = colorSumFore[6].rgb / max(1, pointAmountFore[6]);
	colorResultFore[6].a = pointAmountFore[6] / (6.0 * 6.0 - 1.0);
	colorResultFore[7].rgb = colorSumFore[7].rgb / max(1, pointAmountFore[7]);
	colorResultFore[7].a = pointAmountFore[7] / (7.0 * 7.0);
	colorResultFore[8].rgb = colorSumFore[8].rgb / max(1, pointAmountFore[8]);
	colorResultFore[8].a = pointAmountFore[8] / (8.0 * 8.0 - 1.0);
	colorResultFore[9].rgb = colorSumFore[9].rgb / max(1, pointAmountFore[9]);
	colorResultFore[9].a = pointAmountFore[9] / (9.0 * 9.0);
	colorResultFore[10].rgb = colorSumFore[10].rgb / max(1, pointAmountFore[10]);
	colorResultFore[10].a = pointAmountFore[10] / (10.0 * 10.0 - 1.0);
	colorResultFore[11].rgb = colorSumFore[11].rgb / max(1, pointAmountFore[11]);
	colorResultFore[11].a = pointAmountFore[11] / (11.0 * 11.0);

	colorResultBack[0].rgb = colorSumBack[0].rgb / pointAmountBack[0];
	colorResultBack[0].a = colorSumBack[0].a / (0 * 0);
	colorResultBack[1].rgb = colorSumBack[1].rgb / pointAmountBack[1];
	colorResultBack[1].a = colorSumBack[1].a / (1 * 1);
	colorResultBack[2].rgb = colorSumBack[2].rgb / pointAmountBack[2];
	colorResultBack[2].a = colorSumBack[2].a / (2 * 2);
	colorResultBack[3].rgb = colorSumBack[3].rgb / pointAmountBack[3];
	colorResultBack[3].a = colorSumBack[3].a / (3 * 3);
	colorResultBack[4].rgb = colorSumBack[4].rgb / pointAmountBack[4];
	colorResultBack[4].a = colorSumBack[4].a / (4 * 4);
	colorResultBack[5].rgb = colorSumBack[5].rgb / pointAmountBack[5];
	colorResultBack[5].a = colorSumBack[5].a / (5 * 5);
	colorResultBack[6].rgb = colorSumBack[6].rgb / pointAmountBack[6];
	colorResultBack[6].a = colorSumBack[6].a / (6 * 6);
	colorResultBack[7].rgb = colorSumBack[7].rgb / pointAmountBack[7];
	colorResultBack[7].a = colorSumBack[7].a / (7 * 7);
	colorResultBack[8].rgb = colorSumBack[8].rgb / pointAmountBack[8];
	colorResultBack[8].a = colorSumBack[8].a / (8 * 8);
	colorResultBack[9].rgb = colorSumBack[9].rgb / pointAmountBack[9];
	colorResultBack[9].a = colorSumBack[9].a / (9 * 9);
	colorResultBack[10].rgb = colorSumBack[10].rgb / pointAmountBack[10];
	colorResultBack[10].a = colorSumBack[10].a / (10 * 10);
	colorResultBack[11].rgb = colorSumBack[11].rgb / pointAmountBack[11];
	colorResultBack[11].a = colorSumBack[11].a / (11 * 11);

//	gl_FragColor = colorResultFore[11];//textureRect(scene, gl_FragCoord);
//	return;


	vec4 blendColor0;
	vec4 blendColor1 = colorResultFore[0];
	//	gl_FragColor = vec4(blendColor1.rgb * blendColor1.a, 1.0);
//	return;

	blendColor1.a =  blendColor1.a + colorResultFore[1].a - colorResultFore[1].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[1].rgb, colorResultFore[1].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[2].a - colorResultFore[2].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[2].rgb, colorResultFore[2].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[3].a - colorResultFore[3].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[3].rgb, colorResultFore[3].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[4].a - colorResultFore[4].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[4].rgb, colorResultFore[4].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[5].a - colorResultFore[5].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[5].rgb, colorResultFore[5].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[6].a - colorResultFore[6].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[6].rgb, colorResultFore[6].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[7].a - colorResultFore[7].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[7].rgb, colorResultFore[7].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[8].a - colorResultFore[8].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[8].rgb, colorResultFore[8].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
//	blendColor1.a =  clamp(blendColor1.a + colorResultFore[9].a, 0.0, 1.0);// - colorResultFore[10].a * blendColor1.a;
	blendColor1.a =  blendColor1.a + colorResultFore[9].a - colorResultFore[9].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[9].rgb, colorResultFore[9].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
//	blendColor1.a =  clamp(blendColor1.a + colorResultFore[10].a, 0.0, 1.0);// - colorResultFore[10].a * blendColor1.a;
	blendColor1.a =  blendColor1.a + colorResultFore[10].a - colorResultFore[10].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[10].rgb, colorResultFore[10].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[11].a - colorResultFore[11].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[11].rgb, colorResultFore[11].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;


		gl_FragColor = vec4(blendColor1.rgb * blendColor1.a, 1.0);
		return;
//	if(blendColor1.a > 0)
//	gl_FragColor = mix(textureRect(scene, gl_FragCoord.xy), blendColor1, blendColor1.a);

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