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

	float currentDepth = CocAndDepth.g;
	float focusDepth=textureRect(CocAndDepthMap, vec2(FocusX, FocusY)).g;
	int currentCoc = int(CocAndDepth.r);
//	gl_FragColor = textureRect(scene2, gl_FragCoord.xy);
//	gl_FragColor =  vec4(currentCoc / 11.0, 0.25, 0.75,0);//*/FocusBlur(MaxOutputDCoC, fd, 15);//textureRect(scene, gl_FragCoord.xy);//smoothBlur(vec2(width,height), fd*MaxDistance, 100);
//	  gl_FragColor =  vec4(currentDepth / 10, currentDepth / 50, currentDepth / 50,1);														// ��ʾ���ͼ
//	return;


	float tmpX, tmpY;
	float mean, zeta = 0;
	float depth;
	vec2 tmpXY;

	int tempCoc;
	float tempDepth;
	int tempCoc2;
	float tempDepth2;

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
			tempDepth = CocAndDepth.g;
			tempCoc2 = int(CocAndDepth.b);
			tempDepth2 = CocAndDepth.a;

			int l1, l2;
			int d1, d2;
			d1 = clamp(int (1.0 - tempDepth + focusDepth), 0, 1);//clamp(focusDepth + 1 - tempDepth, 0.0, 1.0);
			d2 = clamp(int (1.0 - tempDepth2 + focusDepth), 0, 1);
	//		if((abs(col) * 2>= tempCoc) || (abs(row) * 2 > tempCoc))
	//			l = 0;
			l1 = clamp(tempCoc - abs(col) * 2, 0, 1) *  clamp(tempCoc - abs(row) * 2, 0, 1);
			l2 = clamp(tempCoc2 - abs(col) * 2, 0, 1) *  clamp(tempCoc2 - abs(row) * 2, 0, 1);

			l1 = d1 * l1;
			l2 = d2 * l2;
			vec4 color4 = textureRect(scene, tmpXY);
			vec4 color42 = textureRect(scene2, tmpXY);
			int k1, k2, k22;
			k1 = abs(tempCoc - 1);
				k1 = (1 - clamp(k1, 0, 1)) * l1;
			k2 = abs(tempCoc2 - 1);
				k2 = (1 - clamp(k2, 0, 1)) * l2;
				k22 = clamp(k2 - k1, 0, 1);
				colorSumFore[1] += (k1 *color4 + k22 * color42);
				pointAmountFore[1] += (k1 + k22);

			k1 = abs(tempCoc - 3);
				k1 = (1 - clamp(k1, 0, 1)) * l1;
			k2 = abs(tempCoc2 - 3);
				k2 = (1 - clamp(k2, 0, 1)) * l2;
				k22 = clamp(k2 - k1, 0, 1);
				colorSumFore[3] += (k1 *color4 + k22 * color42);
				pointAmountFore[3] += (k1 + k22);

			k1 = abs(tempCoc - 5);
				k1 = (1 - clamp(k1, 0, 1)) * l1;
			k2 = abs(tempCoc2 - 5);
				k2 = (1 - clamp(k2, 0, 1)) * l2;
				k22 = clamp(k2 - k1, 0, 1);
				colorSumFore[5] += (k1 *color4 + k22 * color42);
				pointAmountFore[5] += (k1 + k22);

			k1 = abs(tempCoc - 7);
				k1 = (1 - clamp(k1, 0, 1)) * l1;
			k2 = abs(tempCoc2 - 7);
				k2 = (1 - clamp(k2, 0, 1)) * l2;
				k22 = clamp(k2 - k1, 0, 1);
				colorSumFore[7] += (k1 *color4 + k22 * color42);
				pointAmountFore[7] += (k1 + k22);

			k1 = abs(tempCoc - 9);
				k1 = (1 - clamp(k1, 0, 1)) * l1;
			k2 = abs(tempCoc2 - 9);
				k2 = (1 - clamp(k2, 0, 1)) * l2;
				k22 = clamp(k2 - k1, 0, 1);
				colorSumFore[9] += (k1 *color4 + k22 * color42);
				pointAmountFore[9] += (k1 + k22);

			k1 = abs(tempCoc - 11);
				k1 = (1 - clamp(k1, 0, 1)) * l1;
			k2 = abs(tempCoc2 - 11);
				k2 = (1 - clamp(k2, 0, 1)) * l2;
				k22 = clamp(k2 - k1, 0, 1);
				colorSumFore[11] += (k1 *color4 + k22 * color42);
				pointAmountFore[11] += (k1 + k22);

		}
	}

	colorResultFore[1].rgb = colorSumFore[1].rgb / max(1, pointAmountFore[1]);
	colorResultFore[1].a = pointAmountFore[1] / (1.0);
	colorResultFore[3].rgb = colorSumFore[3].rgb / max(1, pointAmountFore[3]);
	colorResultFore[3].a = pointAmountFore[3] / (3.0 * 3.0);
	colorResultFore[5].rgb = colorSumFore[5].rgb / max(1, pointAmountFore[5]);
	colorResultFore[5].a = pointAmountFore[5] / (5.0 * 5.0);
	colorResultFore[7].rgb = colorSumFore[7].rgb / max(1, pointAmountFore[7]);
	colorResultFore[7].a = pointAmountFore[7] / (7.0 * 7.0);
	colorResultFore[9].rgb = colorSumFore[9].rgb / max(1, pointAmountFore[9]);
	colorResultFore[9].a = pointAmountFore[9] / (9.0 * 9.0);
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
	vec4 blendColor1 = colorResultFore[1];
//		gl_FragColor = vec4(blendColor1.rgb * blendColor1.a, 1.0);
//	return;

	blendColor1.a =  blendColor1.a + colorResultFore[3].a - colorResultFore[3].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[3].rgb, colorResultFore[3].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[5].a - colorResultFore[5].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[5].rgb, colorResultFore[5].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[7].a - colorResultFore[7].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[7].rgb, colorResultFore[7].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
//	blendColor1.a =  clamp(blendColor1.a + colorResultFore[9].a, 0.0, 1.0);// - colorResultFore[10].a * blendColor1.a;
	blendColor1.a =  blendColor1.a + colorResultFore[9].a - colorResultFore[9].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[9].rgb, colorResultFore[9].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;
	blendColor1.a =  blendColor1.a + colorResultFore[11].a - colorResultFore[11].a * blendColor1.a;
	blendColor1.rgb = mix(blendColor1.rgb, colorResultFore[11].rgb, colorResultFore[11].a / max(0.000001f, blendColor1.a)) ;//+ (colorResultFore[10].rgb - colorResultFore[11].rgb) * (0) / colorResultFore[11].a;


		gl_FragColor = vec4(blendColor1.rgb * blendColor1.a, 1.0);
//		return;
	if(blendColor1.a > 0)
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