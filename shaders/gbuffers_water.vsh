#version 430 compatibility
#define ITERATIONS 10

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out float offset; 
out vec3 worldPos;
out vec3 noise;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform int frameCounter;
uniform sampler2D noisetex;

//https://www.shadertoy.com/view/MdXyzX
vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
  float x = dot(direction, position) * frequency + timeshift;
  float wave = exp(sin(x) - 1.0);
  float dx = wave * cos(x);
  return vec2(wave, -dx);
}


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = (lmcoord * 33.05 / 32.0) - (1.05 / 32.0);

	normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
	normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space
	glcolor = gl_Color;
	vec4 viewpos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec4 position = viewpos;
	position.xyz += cameraPosition.xyz;
	float frames = float(frameCounter)/10;
	float iter = 0;
	float sumOfValues = 0.0;
	vec3 normalSum = vec3(0.0);
	float freq = 0.1;
	for (int i = 0; i < ITERATIONS; i++){
		vec2 dir = vec2(sin(iter),cos(iter));
		vec2 res = wavedx(position.xz * 20,dir,freq,frames);
		sumOfValues += res.x;
		normalSum += vec3(dir.x *freq * res.y, dir.y * freq * res.y, freq * res.x);
		freq *= 1.18;
		iter += 1.15;
	}	

	position.y += sumOfValues/12 - 0.5;
	// normal.x += normalSum.x/2;
	// normal.z += normalSum.y/2;
	offset = sumOfValues/10;
			worldPos = position.xyz;
			position.xyz -= cameraPosition.xyz;
			gl_Position = (gl_ProjectionMatrix * gbufferModelView * position); //seus type conversion
			//gl_Position.xyz /= gl_Position.w;

}

//