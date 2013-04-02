//--------------------------------------------------------------------------------------
// Order Independent Transparency with Depth Peeling
//
// Author: Louis Bavoil
// Email: sdkfeedback@nvidia.com
//
// Copyright (c) NVIDIA Corporation. All rights reserved.
//--------------------------------------------------------------------------------------
#extension GL_ARB_texture_rectangle : enable
#extension GL_EXT_gpu_shader4 : enable
uniform vec3 BackgroundColor;

uniform samplerRECT scene;
uniform samplerRECT scene2;
uniform samplerRECT CocAndDepthMap;
//uniform samplerRECT CoCMap;

uniform float width;
uniform float height;
uniform float FocusX;
uniform float FocusY;

//float MaxDistance = 40.0;

float MaxOutputDCoC;
float ClearCoc;
vec4 BilateralBlur(vec2 texSize, int KernelDiameter, float focusDist, float sigmaD, bool far);
vec4 FrontBlur(int KernelDiameter, float focusDist, float sigmaD);
vec4 BackBlur(int KernelDiameter, float focusDist, float sigmaD, float myCoc, float myDist);
vec4 FocusBlur(int KernelDiameter, float focusDist, float sigmaD);
void main(void)
{
//	vec4 frontColor = textureRect(ColorTex, gl_FragCoord.xy);
//	gl_FragColor.rgb = BackgroundColor;// + BackgroundColor * frontColor.a;

	vec4 CocAndDepth = textureRect(CocAndDepthMap, gl_FragCoord.xy);

	float depth = CocAndDepth.g;
	float fd=textureRect(CocAndDepthMap, vec2(FocusX, FocusY)).g;

	float tmpCoC = CocAndDepth.r;
	int DCoC = int(tmpCoC);
		//gl_FragColor = textureRect(scene, gl_FragCoord.xy);			// 显示scene
 //    gl_FragColor = textureRect(scene2, gl_FragCoord.xy);			// 显示第二层scene
//	  gl_FragColor =  vec4(depth / 200, depth / 200, depth / 200,1);														// 显示深度图
//	  return;
   if(DCoC <= ClearCoc)
   {
      gl_FragColor =  vec4(DCoC* 0.25, 0.25, 0.75,0);//*/FocusBlur(MaxOutputDCoC, fd, 15);//textureRect(scene, gl_FragCoord.xy);//smoothBlur(vec2(width,height), fd*MaxDistance, 100);
   }
   //else if(DCoC > MaxOutputDCoC)
   //{
   //   gl_FragColor =  vec4(1.0,0,0,0);//textureRect(scene, gl_FragCoord.xy);//smoothBlur(vec2(width,height), fd*MaxDistance, 100);
   //}
   else{
//   gl_FragColor = textureRect(CoCMap, gl_FragCoord.xy);
//   #if 0

  if(depth > fd)
      gl_FragColor =  vec4(DCoC* 0.25, 0.25, 0.75,0);//*/BackBlur(DCoC, fd, 15, DCoC, depth);
  else
      gl_FragColor =  FrontBlur(DCoC, fd, 15);
	  }
//	  #endif

}
float laplace(vec2 p)
{
	float result0 = textureRect(CocAndDepthMap, p).g;
	float result1 = 0;
	result1 -= textureRect(CocAndDepthMap, p + vec2(1.0, 0)).g;
	result1 -= textureRect(CocAndDepthMap, p + vec2(-1.0, 0)).g;
	result1 -= textureRect(CocAndDepthMap, p + vec2(0, 1.0)).g;
	result1 -= textureRect(CocAndDepthMap, p + vec2(0, -1.0)).g;
	//result1 -= textureRect(depthMap, p + vec2(1, 1)).r;
	//result1 -= textureRect(depthMap, p + vec2(-1, 1)).r;
	//result1 -= textureRect(depthMap, p + vec2(-1, 1)).r;
	//result1 -= textureRect(depthMap, p + vec2(-1, -1)).r;
	result1 *= 0.25;
	return abs(result0 + result1);
//	return abs(textureRect(depthMap, p + vec2(0, 1.0)).r - textureRect(depthMap, p + vec2(0, -1.0)).r);
}
bool isDifferentLayer(vec2 src, vec2 des)
{
	int dx = des.x - src.x;
	int dy = des.y - src.y;
	int adx = abs(dx);
	int ady = abs(dy);
	float scale = 1;
	float stepX = scale*dx/adx, stepY = scale*dy/ady;
	int i; 
	int maxD;
	if(adx > ady){
		stepY = scale*dy / adx;
		maxD = adx;
	}
	else{
		stepX = scale*dx / ady;
		maxD = ady;
	}
	vec2 currentP = src;
	for(i = 0; i< maxD; i += scale)
	{	
		currentP.x += stepX;
		currentP.y += stepY;
		if( laplace(currentP) >=0.5)
			return true;
	}
	return false;
}
vec4 FocusBlur(int KernelDiameter, float focusDist, float sigmaD)
{
	bool nearFront = false, breakFlag = false;
	int KernelRadius=KernelDiameter/2;
	int _KernelRadius = KernelDiameter - KernelRadius;
	float tmpX, tmpY,curCoC = 0.0;
	float mean, zeta = 0;
	float depth;
	vec2 tmpXY;
	vec4 CocAndDepth;
	for(int col=-KernelRadius;col<_KernelRadius;col+=1)
	{
		for(int row=-KernelRadius;row<_KernelRadius;row+=1)
		{
			tmpX = clamp(gl_FragCoord.x+col,0.5,width - 0.5);
			tmpY = clamp(gl_FragCoord.y+row,0.5,height - 0.5);
			tmpXY= vec2(tmpX, tmpY);
			CocAndDepth = textureRect(CocAndDepthMap, tmpXY);
			curCoC = CocAndDepth.r;
			if( curCoC > ClearCoc ){
				depth = CocAndDepth.g;
				if(depth < focusDist){
					if(isDifferentLayer(gl_FragCoord, tmpXY)){
						nearFront = true;
						breakFlag = true;
						break;
					}
				}
			}
		}
		if(breakFlag)
			break;
	}
	if(!nearFront)
		return textureRect(scene, gl_FragCoord.xy);
	else{				// 只高斯前景，剔除清晰区域
//		return vec4(0.5,0.0,0,0);//textureRect(scene, gl_FragCoord.xy);
		float squareDistance;
		float offset=0;
		if(KernelDiameter%2==0)
			offset = 0.5;
		float range=10;
		float sigmaR = 4.0;
   		float depth;
		float x, y, kernelValue,  sum=0;
		vec4 resultColor = vec4(0,0,0,0);
		float sum2 = 0;
		bool isTransparent;
		for(int col=-KernelRadius;col<_KernelRadius;col++)
		{
			for(int row=-KernelRadius;row<_KernelRadius;row++)
			{
				tmpX = clamp(gl_FragCoord.x+col,0.5,width - 0.5);
				tmpY = clamp(gl_FragCoord.y+row,0.5,height - 0.5);
				tmpXY=vec2(tmpX , tmpY);
         
				CocAndDepth = textureRect(CocAndDepthMap, tmpXY);
				depth = CocAndDepth.g;
				if(depth < focusDist){
					curCoC = CocAndDepth.r;
					if( curCoC > ClearCoc ){
						squareDistance = col * col + row * row;
						if(squareDistance < curCoC * curCoC * 0.5){
							isTransparent = false;
						}
						else
							isTransparent = true;
					}
					else
						isTransparent = true;
				}
				else
					isTransparent = true;

				////calculate kernel
				x = (float(col) + offset) / KernelDiameter * range;
				y = (float(row) + offset) / KernelDiameter * range;
				kernelValue = exp(-(x*x + y*y)/(2*sigmaD*sigmaD));

				if(isTransparent){
					sum2 += kernelValue;
				}
				else{
				//Convolution
					sum += kernelValue;
					resultColor += kernelValue * textureRect(scene, tmpXY);
				}
			}
		}
		float alpha = resultColor.a / (sum + sum2);
		if(sum != 0)
			resultColor /= sum;
		return vec4(resultColor.rgb * alpha + textureRect(scene, gl_FragCoord).rgb * (1.0 - alpha), 1);
	}
}
vec4 FrontBlur(int KernelDiameter, float focusDist, float sigmaD)
{
	bool nearFocus = false, breakFlag = false;
	int KernelRadius=KernelDiameter/2;
	int _KernelRadius = KernelDiameter - KernelRadius;
	float tmpX, tmpY,curCoC = 0.0;
	float mean, zeta = 0;
	vec2 tmpXY;
	vec4 CocAndDepth;
	for(int col=-KernelRadius;col<_KernelRadius;col+=1)
	{
		for(int row=-KernelRadius;row<_KernelRadius;row+=1)
		{
			tmpX = clamp(gl_FragCoord.x+col,0.5,width - 0.5);
			tmpY = clamp(gl_FragCoord.y+row,0.5,height - 0.5);
			tmpXY= vec2(tmpX, tmpY);
			CocAndDepth = textureRect(CocAndDepthMap, tmpXY);
			curCoC = CocAndDepth.r;
			if( curCoC <= ClearCoc ){//abs(depth[0]-focusDist)<3
				if(isDifferentLayer(gl_FragCoord, tmpXY)){
					nearFocus = true;
					breakFlag = true;
					break;
				}
			}
		}
		if(breakFlag)
			break;
	}
	//if(nearFocus)
	//	return vec4(1,0,0,1);
	//else
	//	return vec4(0,1,1,1);

	float offset=0;
	if(KernelDiameter%2==0)
		offset = 0.5;
	float range=10;
	float sigmaR = 4.0;
   	float depth;
	float x, y, kernelValue,  sum=0;
	vec4 resultColor = vec4(0,0,0,0);

	if(!nearFocus){		// 普通高斯
		for(int col=-KernelRadius;col<_KernelRadius;col++)
		{
			for(int row=-KernelRadius;row<_KernelRadius;row++)
			{
				tmpX = clamp(gl_FragCoord.x+col,0.5,width - 0.5);
				tmpY = clamp(gl_FragCoord.y+row,0.5,height - 0.5);
				tmpXY=vec2(tmpX , tmpY);
         
				////calculate kernel
				x = (float(col) + offset) / KernelDiameter * range;
				y = (float(row) + offset) / KernelDiameter * range;
				kernelValue = exp(-(x*x + y*y)/(2*sigmaD*sigmaD));

				sum += kernelValue;

				//Convolution
				resultColor += kernelValue * textureRect(scene, tmpXY);

			}
		}
		resultColor /= sum;
	}
	else{				// 只高斯前景，剔除清晰区域
		float sum2 = 0;
		bool isTransparent;
		for(int col=-KernelRadius;col<_KernelRadius;col++)
		{
			for(int row=-KernelRadius;row<_KernelRadius;row++)
			{
				tmpX = clamp(gl_FragCoord.x+col,0.5,width - 0.5);
				tmpY = clamp(gl_FragCoord.y+row,0.5,height - 0.5);
				tmpXY=vec2(tmpX , tmpY);
         
				CocAndDepth = textureRect(CocAndDepthMap, tmpXY);
				curCoC = CocAndDepth.r;
				if( curCoC > ClearCoc ){
					depth = CocAndDepth.g;
					if(depth < focusDist){
						isTransparent = false;
					}
					else
						isTransparent = true;
				}
				else
					isTransparent = true;

				////calculate kernel
				x = (float(col) + offset) / KernelDiameter * range;
				y = (float(row) + offset) / KernelDiameter * range;
				kernelValue = exp(-(x*x + y*y)/(2*sigmaD*sigmaD));

				if(isTransparent){
					sum2 += kernelValue;
				}
				else{
				//Convolution
				sum += kernelValue;
				resultColor += kernelValue * textureRect(scene, tmpXY);
				}
			}
		}
		float alpha = resultColor.a / (sum + sum2);
		resultColor /= sum;
		resultColor = vec4(resultColor.rgb * alpha + textureRect(scene2, gl_FragCoord).rgb * (1.0 - alpha), 1);
	}
	return resultColor;
}

vec4 BackBlur(int KernelDiameter, float focusDist, float sigmaD, float myCoc, float myDist)
{
	bool nearFocus = false, breakFlag = false;
	int KernelRadius=KernelDiameter/2;
	int _KernelRadius = KernelDiameter - KernelRadius;
	float tmpX, tmpY,curCoC = 0.0;
	float mean, zeta = 0;
	vec2 tmpXY;
	vec4 CocAndDepth;
	for(int col=-KernelRadius;col<_KernelRadius;col+=1)
	{
		for(int row=-KernelRadius;row<_KernelRadius;row+=1)
		{
			tmpX = clamp(gl_FragCoord.x+col,0.5,width - 0.5);
			tmpY = clamp(gl_FragCoord.y+row,0.5,height - 0.5);
			tmpXY= vec2(tmpX, tmpY);
			CocAndDepth = textureRect(CocAndDepthMap, tmpXY);
			curCoC = CocAndDepth.r;
			if( curCoC <= ClearCoc ){//abs(depth[0]-focusDist)<3
				if(isDifferentLayer(gl_FragCoord, tmpXY)){
					nearFocus = true;
					breakFlag = true;
					break;
				}
			}
		}
		if(breakFlag)
			break;
	}
	//if(nearFocus)
	//	return vec4(1,0,0,1);
	//else
	//	return vec4(0,1,1,1);

	float offset=0;
	if(KernelDiameter%2==0)
		offset = 0.5;
	float range=10;
	float sigmaR = 4.0;
   	float depth;
	float x, y, kernelValue,  sum=0;
	vec4 resultColor = vec4(0,0,0,0);
	float squareDistance;
	if(!nearFocus){		// 普通高斯
		for(int col=-KernelRadius;col<_KernelRadius;col++)
		{
			for(int row=-KernelRadius;row<_KernelRadius;row++)
			{
				tmpX = clamp(gl_FragCoord.x+col,0.5,width - 0.5);
				tmpY = clamp(gl_FragCoord.y+row,0.5,height - 0.5);
				tmpXY=vec2(tmpX , tmpY);
         
				CocAndDepth = textureRect(CocAndDepthMap, tmpXY);
				curCoC = CocAndDepth.r;

				if( curCoC <= myCoc){
					squareDistance = col * col + row * row;
					if(squareDistance > curCoC * curCoC * 0.5){
				//		continue;
					}
				}
				////calculate kernel
				x = (float(col) + offset) / KernelDiameter * range;
				y = (float(row) + offset) / KernelDiameter * range;
				kernelValue = exp(-(x*x + y*y)/(2*sigmaD*sigmaD));
				kernelValue = 1;
				sum += kernelValue;

				//Convolution
				resultColor += kernelValue * textureRect(scene, tmpXY);

			}
		}
		resultColor /= sum;
	}
	else{				// 只高斯背景，剔除清晰区域
		float sum2 = 0;
		bool discardThis = false;
		float squareDistance;
		for(int col=-KernelRadius;col<_KernelRadius;col++)
		{
			for(int row=-KernelRadius;row<_KernelRadius;row++)
			{
				tmpX = clamp(gl_FragCoord.x+col,0.5,width - 0.5);
				tmpY = clamp(gl_FragCoord.y+row,0.5,height - 0.5);
				tmpXY=vec2(tmpX , tmpY);
         
				CocAndDepth = textureRect(CocAndDepthMap, tmpXY);
				curCoC = CocAndDepth.r;

				if( curCoC <= ClearCoc ){
					discardThis = true;
				}
				else{
					depth = CocAndDepth.g;
					if(curCoC <= myCoc){
						squareDistance = col * col + row * row;
						if(squareDistance > curCoC * curCoC * 0.5){
							discardThis = true;
						}
						else
							discardThis = false;
					}
					else
						discardThis = false;
				}
				if(!discardThis){
					////calculate kernel
					x = (float(col) + offset) / KernelDiameter * range;
					y = (float(row) + offset) / KernelDiameter * range;
					kernelValue = exp(-(x*x + y*y)/(2*sigmaD*sigmaD));

					//Convolution
					sum += kernelValue;
					resultColor += kernelValue * textureRect(scene, tmpXY);
				}
			}
		}
		resultColor /= sum;
	}
	return resultColor;
}


//vec4 BilateralBlur(vec2 texSize, int KernelDiameter, float focusDist, float sigmaD, bool far)
//{
//   //sigmaR = sigmaR - KernelDiameter*45;
//   //sigmaD = KernelDiameter*13 +sigmaD;
//   float sigmaR = 4.0;
//   int KernelRadius=KernelDiameter/2;
//   int _KernelRadius = KernelDiameter - KernelRadius;
//   float range=10;
//   float x, y, lowValue, rangeValue, kernelValue, depthValue, focusValue, sum=0;
//   float tmpX, tmpY,curCoC = 0.0;
//   float mean, zeta = 0;
//   vec2 tmpXY;
//   vec4 resultColor = vec4(0,0,0,0);
//   vec4 centerColor = vec4(0,0,0,0);
//   vec4 centerDepth = vec4(0,0,0,0);
//   vec4 depth = vec4(0,0,0,0);
//   bool nearFocus = false;

//   //当kernel大小为偶数时， 用offset使计算kernelValue时所有(x,y)关于原点对称
//   float offset=0;
//   if(KernelDiameter%2==0)
//      offset = 0.5;

//   centerDepth = textureRect(depthMap, gl_FragCoord.xy);
 
//   mean = 0;
//   for(int col=-KernelRadius;col<_KernelRadius;col++)
//   {
//      for(int row=-KernelRadius;row<_KernelRadius;row++)
//      {
//         tmpX = clamp(gl_FragCoord.x+col,0.5,width - 0.5);
//         tmpY = clamp(gl_FragCoord.y+row,0.5,height - 0.5);
//         tmpXY= vec2(tmpX, tmpY);
//         depth = textureRect(depthMap, tmpXY);
//         curCoC = MaxOutputDCoC * textureRect(CoCMap, tmpXY).r;
//         if( curCoC <= ClearCoc )//abs(depth[0]-focusDist)<3
//            nearFocus = true;
//         mean += depth[0];
//      }
//   }
//   mean /= (KernelDiameter * KernelDiameter);
   
////   return vec4(1,0,0,1);
//   for(int col=-KernelRadius;col<_KernelRadius;col++)
//   {
//      for(int row=-KernelRadius;row<_KernelRadius;row++)
//      {
//         tmpX = clamp(gl_FragCoord.x+col,0.5,width - 0.5);
//         tmpY = clamp(gl_FragCoord.y+row,0.5,height - 0.5);
//         tmpXY=vec2(tmpX , tmpY);
//         depth = textureRect(depthMap, tmpXY);
         
         
//         ////calculate kernel
//         x = (float(col) + offset) / KernelDiameter * range;
//         y = (float(row) + offset) / KernelDiameter * range;
//         lowValue = exp(-(x*x + y*y)/(2*sigmaD*sigmaD));
//         if( nearFocus /*&& far*/)
//         {
//			if(far)
//			{
//				zeta = 0;//centerDepth[0] - mean;
//				sigmaR = 1;
//			}
//			 else
//			 {
//				zeta = 0;//centerDepth[0] - mean;
//				//xiaoting:1
//				sigmaR = 1;
//			}
			 
//		  }
//		  else
//		  {
//			zeta = mean - centerDepth[0];   
//			sigmaR = 100;
//		  }
//         depthValue = exp(-(pow(centerDepth[0] - depth[0] - zeta, 2.0))/(2*sigmaR*sigmaR));
////		 depthValue = 1;
//         kernelValue = lowValue * depthValue;
//		 //kernelValue = 1;
//         sum += kernelValue;

//         //Convolution
//         resultColor += kernelValue * textureRect(scene, tmpXY);

//      }
//   }
//   resultColor /= sum;

//   return resultColor;
  
//}