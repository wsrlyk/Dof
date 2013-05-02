#extension GL_EXT_gpu_shader4 : enable 
 #extension GL_ARB_texture_rectangle : enable

uniform sampler2DArray layerArray;

uniform float width;
uniform float height;

#define Klayers 23

void main()
{
//	gl_FragColor = texture2DArray(layerArray, vec3(gl_FragCoord.xy, 0));
//	gl_FragColor = texture2DArray(layerArray, vec3(gl_FragCoord.x/width, gl_FragCoord.y/height, 22));
//	return;

	vec4 result = vec4(0, 0, 0, 0);
	vec4 buffer;
	for(int i = Klayers - 1; i >= 0; --i)
	{
		int DCoC = abs(11 - i);
		int radius = DCoC / 2;
		int _radius = DCoC - radius;
		float weight = 1.0 / (DCoC * DCoC);
		buffer = vec4(0, 0, 0, 0);
		for(int j = -radius; j < _radius; ++j)
			for(int k = -radius; k < _radius; ++k)
			{
				buffer += weight * texture2DArray(layerArray, vec3((gl_FragCoord.x + j)/width, (gl_FragCoord.y + k)/height, i));
			}
		
		if( i == Klayers - 1)
		{
			result = buffer;
		}
		else
		{
			result.a = result.a + buffer.a - result.a * buffer.a;
			if(result.a != 0)
			{
				result.rgb = result.rgb + (buffer.rgb - result.rgb) * buffer.a / result.a;
			}
		}
	}
	gl_FragColor = result;
}