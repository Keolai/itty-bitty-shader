#version 430 compatibility

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
	noise = texture(noisetex, (position.xz * vec2(0.05) + vec2(frames/40))).rgb;
	//offset = exp(sin(frames + position.x + noise.r));
	offset = sin(position.x * 10 + noise.r + frames) * 1.5 + cos(position.z + noise.r);
	float slope =1.5 * cos(position.x * 10 + noise.r + frames) - sin(position.z + noise.r);
	normal.x += -slope ;

	//offset = noise.r/2.;
	//normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
	//normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space
	//blockID = int(mc_Entity.x);
			position.y += offset/20;
			position.z += offset/40;
			worldPos = position.xyz;
			position.xyz -= cameraPosition.xyz;
			gl_Position = (gl_ProjectionMatrix * gbufferModelView * position); //seus type conversion
			//gl_Position.xyz /= gl_Position.w;

}