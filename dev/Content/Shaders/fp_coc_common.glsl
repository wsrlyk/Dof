float MaxOutputDCoC;
uniform float zFar;
uniform float zNear;

int CalculateDCoC(float fd, float z)
{
   //单位都是cm
   float D=30.0f;
   float f=100.0f;
   float a = z - f;
   if(abs(a)<0.00001)
      a = 0.00001;
   float RawDCoC = abs((D*f*(fd-z))/(fd*a));
   float MaxRawDCoC = MaxOutputDCoC;
   
   float result = MaxOutputDCoC * clamp(RawDCoC/MaxRawDCoC, 0, 1);
   return int(result+0.5) / 2 * 2 + 1;
}

float getRealZ(float z_b)
{
	float z_n = 2.0 * z_b - 1.0;
    return 2.0 * zNear * zFar / (zFar + zNear - z_n * (zFar - zNear));
}