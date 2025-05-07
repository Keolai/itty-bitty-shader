#version 330 compatibility

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out float offset; 

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
	glcolor = gl_Color;
	vec4 viewpos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec4 position = viewpos;
	position.xyz += cameraPosition.xyz;
	float frames = float(frameCounter)/7000;
	vec4 noise = texture(noisetex, (position.xz * vec2(0.1) + vec2(frames)));
	//offset = pow(float(sin(frames * 0.0002 * position.x )) * sin(position.z * frames * 0.0002),2.)/15;
	offset = noise.r/2.;
	//normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
	//normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space
	//blockID = int(mc_Entity.x);
			position.y += offset/10;
			position.xyz -= cameraPosition.xyz;
			gl_Position = (gl_ProjectionMatrix * gbufferModelView * position); //seus type conversion
			//gl_Position.xyz /= gl_Position.w;

}