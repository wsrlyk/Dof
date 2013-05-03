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

float CalculateDepthFromCoC(float focus_z, int coc);
void main(void)
{

	vec4 CocAndDepth = textureRect(CocAndDepthMap, gl_FragCoord.xy);
	vec4 currentColor = vec4(textureRect(scene, gl_FragCoord.xy).rgb, 1.0);
	vec4 currentColor2 = vec4(textureRect(scene2, gl_FragCoord.xy).rgb, 1.0);
	float currentDepth = CocAndDepth.g;
	float currentDepth2 = CocAndDepth.a;
	float focusDepth=textureRect(CocAndDepthMap, vec2(focusX, focusY)).g;
	float currentFloatCoc = CocAndDepth.r;
	int currentCoc = int(currentFloatCoc);
	float currentFloatCoc2 = CocAndDepth.b;
	int currentCoc2 = int(currentFloatCoc2);
//	gl_FragColor = textureRect(scene2, gl_FragCoord.xy);
//	gl_FragColor =  vec4(currentCoc / 11.0, 0.25, 0.75,0);//*/FocusBlur(MaxOutputDCoC, fd, 15);//textureRect(scene, gl_FragCoord.xy);//smoothBlur(vec2(width,height), fd*MaxDistance, 100);
//	  gl_FragColor =  vec4(currentDepth / 10, currentDepth / 50, currentDepth / 50,1);														// 显示深度图
//	return;

	int currentIsFore = currentDepth - focusDepth < 0 ? -1: 1;
	int currentIsFore2 = currentDepth2 - focusDepth < 0 ? -1: 1;

	float maxDistance = 3*CalculateDepthFromCoC(focusDepth, -currentCoc * currentIsFore-1) 
									-  CalculateDepthFromCoC(focusDepth, -currentCoc * currentIsFore);
	float maxDistance2 = CalculateDepthFromCoC(focusDepth, -currentCoc2 * currentIsFore2-1) 
									-  CalculateDepthFromCoC(focusDepth, -currentCoc2 * currentIsFore2);
//	  gl_FragColor =  vec4(maxDistance / 1, 1, 1,1);														// 显示深度图
//	return;

	float tmpX, tmpY;
	float mean, zeta = 0;
	float depth;
	vec2 tmpXY;
	vec2 tmpXYx2;

	int tempCoc;
	float tempFloatCoc;
	float tempDepth;
	int tempCoc2;
	float tempFloatCoc2;
	float tempDepth2;
	int tempIsFore;
	int tempIsFore2;

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
			else if(currentCoc2 == 0)
				buffer = currentColor2;
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
					tempFloatCoc = CocAndDepth.r;
					tempCoc = int(tempFloatCoc);
					tempDepth = CocAndDepth.g;
					tempFloatCoc2 = CocAndDepth.b;
					tempCoc2 = int(tempFloatCoc2);
					tempDepth2 = CocAndDepth.a;

					tmpXYx2 = vec2(abs(col) * 2, abs(row) * 2);
					vec4 color4 = vec4(textureRect(scene, tmpXY).rgb, 1.0);
					vec4 color42 = vec4(textureRect(scene2, tmpXY).rgb, 1.0);

					vec4 result = vec4(0,0,0,0);
					vec4 result2 = vec4(0,0,0,0);

					tempIsFore = tempDepth - focusDepth < 0 ? -1: 1;
					tempIsFore2 = tempDepth2 - focusDepth < 0 ? -1: 1;

					// add temp to current if they are similar
					
					if(currentCoc * currentIsFore == i)
					{
						if( abs(tempCoc - currentCoc) <= 1 &&  tempIsFore == currentIsFore && abs(tempDepth - currentDepth) <= maxDistance)
						{
							result = color4;// * fract(1.0-(tempFloatCoc - currentCoc));
						}
						if( abs(tempCoc2 - currentCoc) <= 1 &&  tempIsFore2 == currentIsFore && abs(tempDepth2 - currentDepth) <= maxDistance)
						{
							result2 = color42;// * fract(1.0-(tempFloatCoc2 - currentCoc));
						}
					}
					else if(currentCoc2 * currentIsFore2 == i)
					{
						if( abs(tempCoc - currentCoc2) <= 1 &&  tempIsFore == currentIsFore2 && abs(tempDepth - currentDepth2) <= maxDistance2)
						{
							result = color4;//*fract(1.0-(tempFloatCoc - currentCoc2));
						}
						if( abs(tempCoc2 - currentCoc2) <= 1 &&  tempIsFore2 == currentIsFore2 && abs(tempDepth2 - currentDepth2) <= maxDistance2)
						{
							result2 = color42;//*fract(1.0-(tempFloatCoc2 - currentCoc));
						}
					}
					
					if(tempCoc * tempIsFore == i)
					{
						result = color4;
					}	// end if

					if(tempCoc2 * tempIsFore2 == i /*&& tempCoc2 != largerCoc/* && tempCoc2 > tmpXYx2.x && tempCoc2 > tmpXYx2.y*/)
					{
						result2 = color42;
					}	// end if

					result2.a = result.a + result2.a - result.a * result2.a;
					if(result2.a > 0)
					{
						result2.rgb = result2.rgb + (result.rgb - result2.rgb) * result.a / result2.a;
					}
					buffer += result2;
				}	//end for row
			}	//end for col
			if(buffer.a != 0){
				buffer.rgb = buffer.rgb / buffer.a;
				buffer.a = buffer.a / (i * i);
			}

		}	// end if DCoc

		result.a = result.a + buffer.a - result.a * buffer.a;
		if(result.a != 0)
		{
			result.rgb = result.rgb + (buffer.rgb - result.rgb) * buffer.a / result.a;
		}

	}	// end for i
//	if(result.a<0.99)
//		gl_FragColor = vec4(1,0,0,1);
//	else
		gl_FragColor = vec4(result.rgb * result.a + vec3(1,1,1)* (1.0 - result.a), 1.0);
	return;

}