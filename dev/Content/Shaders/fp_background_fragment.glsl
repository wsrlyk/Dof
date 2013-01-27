uniform sampler2D srcTexture;

varying vec2 uv;
void main()
{
	gl_FragData[0] = vec4(1, 1, 1, 1);// texture2D(srcTexture, gl_FragCoord);
	gl_FragData[1] = vec4(1, 1, 1, 1);// texture2D(srcTexture, gl_FragCoord);
}