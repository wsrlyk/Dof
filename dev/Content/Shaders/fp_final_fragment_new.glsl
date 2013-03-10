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
		colorSumFore[i] = 0;
		colorSumBack[i] = 0;
		pointAmountFore[i] = 0;
		pointAmountBack[i] = 0;
		colorResultFore[i] = 0;
		colorResultBack[i] = 0;
	}

	for(int col=-halfCoc; col <= halfCoc; col+=1)
	{
		for(int row=-halfCoc; row < halfCoc; row+=1)
		{
			tmpX = clamp(gl_FragCoord.x+col,0.5,width - 0.5);
			tmpY = clamp(gl_FragCoord.y+row,0.5,height - 0.5);
			tmpXY= vec2(tmpX, tmpY);

			CocAndDepth = textureRect(CocAndDepthMap, tmpXY);
			tempCoc = int(CocAndDepth.r);
			tempDepth = int(CocAndDepth.g);

			int l = 1;
			if((abs(col) * 2> tempCoc) || (abs(row) * 2 > tempCoc))
				l = 0;

			vec4 color4 = textureRect(scene, tmpXY);
			if(tempDepth <= focusDepth)
			{
			int k;
			k = abs(0 - tempCoc);
			k = 1 - k / k;
				colorSumFore[0] += k * l *color4;
				pointAmountFore[0] += k * l;
			k = abs(1.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumFore[1] += k * l *color4;
				pointAmountFore[1] += k * l;
			k = abs(2.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumFore[2] += k * l *color4;
				pointAmountFore[2] += k * l;
			k = abs(3.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumFore[3] += k * l *color4;
				pointAmountFore[3] += k * l;
			k = abs(4.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumFore[4] += k * l *color4;
				pointAmountFore[4] += k * l;
			k = abs(5.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumFore[5] += k * l *color4;
				pointAmountFore[5] += k * l;
			k = abs(6.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumFore[6] += k * l *color4;
				pointAmountFore[6] += k * l;
			k = abs(7.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumFore[7] += k * l *color4;
				pointAmountFore[7] += k * l;
			k = abs(8.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumFore[8] += k * l *color4;
				pointAmountFore[8] += k * l;
			k = abs(9.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumFore[9] += k * l *color4;
				pointAmountFore[9] += k * l;
			k = abs(10.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumFore[10] += k * l *color4;
				pointAmountFore[10] += k * l;
			k = abs(11.0 - tempCoc);
			k = 1.0 - k / k;
				colorSumFore[11] += k * l *color4;
				pointAmountFore[11] += k * l;

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
			k = 1.0 - k / k;
				colorSumBack[11] += k * l *color4;
				pointAmountBack[11] += k * l;
			}
		}
	}

	colorResultFore[0].rgb = colorSumFore[0].rgb / pointAmountFore[0];
	colorResultFore[0].a = colorSumFore[0].a / (0 * 0);
	colorResultFore[1].rgb = colorSumFore[1].rgb / pointAmountFore[1];
	colorResultFore[1].a = colorSumFore[1].a / (1 * 1);
	colorResultFore[2].rgb = colorSumFore[2].rgb / pointAmountFore[2];
	colorResultFore[2].a = colorSumFore[2].a / (2 * 2);
	colorResultFore[3].rgb = colorSumFore[3].rgb / pointAmountFore[3];
	colorResultFore[3].a = colorSumFore[3].a / (3 * 3);
	colorResultFore[4].rgb = colorSumFore[4].rgb / pointAmountFore[4];
	colorResultFore[4].a = colorSumFore[4].a / (4 * 4);
	colorResultFore[5].rgb = colorSumFore[5].rgb / pointAmountFore[5];
	colorResultFore[5].a = colorSumFore[5].a / (5 * 5);
	colorResultFore[6].rgb = colorSumFore[6].rgb / pointAmountFore[6];
	colorResultFore[6].a = colorSumFore[6].a / (6 * 6);
	colorResultFore[7].rgb = colorSumFore[7].rgb / pointAmountFore[7];
	colorResultFore[7].a = colorSumFore[7].a / (7 * 7);
	colorResultFore[8].rgb = colorSumFore[8].rgb / pointAmountFore[8];
	colorResultFore[8].a = colorSumFore[8].a / (8 * 8);
	colorResultFore[9].rgb = colorSumFore[9].rgb / pointAmountFore[9];
	colorResultFore[9].a = colorSumFore[9].a / (9 * 9);
	colorResultFore[10].rgb = colorSumFore[10].rgb / pointAmountFore[10];
	colorResultFore[10].a = colorSumFore[10].a / (10 * 10);
	colorResultFore[11].rgb = colorSumFore[11].rgb / pointAmountFore[11];
	colorResultFore[11].a = colorSumFore[11].a / (11 * 11);

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

	gl_FragColor = colorResultFore[11];//textureRect(scene, gl_FragCoord);
	return;


	vec4 blendColor0;
	vec4 blendColor1 = colorResultFore[maxCoc];
	for(int i = maxCoc - 1; i >= 0; --i)
	{
		blendColor0 = blendColor1;
		blendColor1.a = blendColor0.a + colorResultFore[i].a - colorResultFore[i].a * blendColor0.a;
		blendColor1.rgb = blendColor0.rgb + (colorResultFore[i].rgb - blendColor0.rgb) * colorResultFore[i].a / blendColor1.a;
	}
	for(int i = 1; i <= maxCoc; ++i)
	{
		blendColor0 = blendColor1;
		blendColor1.a = blendColor0.a + colorResultBack[i].a - colorResultBack[i].a * blendColor0.a;
		blendColor1.rgb = blendColor0.rgb + (colorResultBack[i].rgb - blendColor0.rgb) * colorResultBack[i].a / blendColor1.a;
	}

	gl_FragColor = blendColor1;
}