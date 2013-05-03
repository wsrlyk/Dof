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

	int currentIsFore = currentDepth - focusDepth < 0 ? -1: 1;
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
	int tempIsFore2;
	int largerCoc;

	vec4 colorSumForeBuffer;
	vec4 colorSumBackBuffer;
	vec4 buffer;
	vec4 result = vec4(0,0,0,0);


	for(int i = maxCoc; i >= -maxCoc; --i)
	{
		int DCoc = abs(i);
		buffer = vec4(0,0,0,0);
		if(DCoc == 0)
		{
			if(currentCoc == 0)
				buffer = currentColor;
			else if(int(CocAndDepth.b) == 0)
				buffer = textureRect(scene2, gl_FragCoord.xy);
		}
		else
		{
			int radius = DCoc / 2;
			int _radius = DCoc - radius;
			for(int col=-radius; col < _radius; col+=1)
			{
				for(int row=-radius; row < _radius; row+=1)
				{
					tmpXY = vec2(gl_FragCoord.x+col, gl_FragCoord.y + row);
					CocAndDepth = textureRect(CocAndDepthMap, tmpXY);
					tempCoc = int(CocAndDepth.r);
					tempDepth = CocAndDepth.g;
					tempCoc2 = int(CocAndDepth.b);
					tempDepth2 = CocAndDepth.a;

					tmpXYx2 = vec2(abs(col) * 2, abs(row) * 2);
					vec4 color4 = vec4(textureRect(scene, tmpXY).rgb, 1.0);
					vec4 color42 = vec4(textureRect(scene2, tmpXY).rgb, 1.0);

					tempIsFore = tempDepth - focusDepth < 0 ? -1: 1;
					tempIsFore2 = tempDepth2 - focusDepth < 0 ? -1: 1;

					largerCoc = tempCoc;
					// add temp to current if they are similar
					if(currentCoc == DCoc && abs(tempCoc - currentCoc) == 1 &&  tempIsFore == currentIsFore)
					{
						largerCoc = currentCoc;
						buffer += color4;
					}

		//			if(tempCoc > tmpXYx2.x && tempCoc > tmpXYx2.y)
					if(tempCoc * tempIsFore == i)
					{
						buffer += color4;
					}	// end if

					if(tempCoc2 * tempIsFore2 == i && tempCoc2 != largerCoc/* && tempCoc2 > tmpXYx2.x && tempCoc2 > tmpXYx2.y*/)
					{
						buffer += color42;
					}	// end if
				}	//end for row
			}	//end for col
			if(buffer.a != 0){
				buffer.rgb = buffer.rgb / buffer.a;
				buffer.a = buffer.a / (i * i);
			}

		}	// end if radius

		result.a = result.a + buffer.a - result.a * buffer.a;
		if(result.a != 0)
		{
			result.rgb = result.rgb + (buffer.rgb - result.rgb) * buffer.a / result.a;
		}

	}	// end for i

	gl_FragColor = vec4(result.rgb * result.a + vec3(1,1,1) * (1.0 - result.a), 1.0);
	return;

}