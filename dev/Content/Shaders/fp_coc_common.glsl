float MaxOutputDCoC;
uniform float zFar;
uniform float zNear;

/* keting
*/
float D=60.0f;
float f=0.2f;

/* beauti
float D=30.0f;
float f=1.1f;
*/

float CalculateDCoC(float focus_z, float z)
{
   //单位都是cm
   float a = z - f;
   if(abs(a)<0.00001)
      a = 0.00001;
   float RawDCoC = abs((D*f*(focus_z-z))/(focus_z*a));
   
   float result = clamp(RawDCoC, 0.0, MaxOutputDCoC);
//   int odd = int(result) / 2 * 2 + 1;
//   return (result - odd) * 0.5 + odd;
//   return int(result+0.5) / 2 * 2 + 1;
	return result;
   //return int(result);

}

float CalculateDepthFromCoC(float focus_z, int coc)
{
	float depth = focus_z * f * (coc + D) / (coc * focus_z + D * f);
	if(depth < 0)
		return 1000;
	return depth;
}
float getRealZ(float z_b)
{
	float z_n = 2.0 * z_b - 1.0;
    return 2.0 * zNear * zFar / (zFar + zNear - z_n * (zFar - zNear));
}