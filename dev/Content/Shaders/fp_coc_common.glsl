float MaxOutputDCoC;
uniform float zFar;
uniform float zNear;

int CalculateDCoC(float focus_z, float z)
{
   //��λ����cm
   float D=30.0f;
   float f=1.1f;
   float a = z - f;
   if(abs(a)<0.00001)
      a = 0.00001;
   float RawDCoC = abs((D*f*(focus_z-z))/(focus_z*a));
   
   float result = clamp(RawDCoC, 1.0, MaxOutputDCoC);
//   int odd = int(result) / 2 * 2 + 1;
//   return (result - odd) * 0.5 + odd;
   return int(result+0.5) / 2 * 2 + 1;
//   return int(result);

}

float CalculateDepthFromCoC(float focus_z, int coc)
{
	float D=30.0f;
	float f=1.1f;
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