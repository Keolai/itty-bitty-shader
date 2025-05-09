#version 430 compatibility
#include /lib/random.glsl
#define VERTEX

#include /lib/cl/common.glsl

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
flat out int blockID;

in vec3 mc_Entity;
in vec3 at_midBlock;


uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform int frameCounter;
uniform float rainStrength;
uniform sampler2D noisetex;


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = (lmcoord * 33.05 / 32.0) - (1.05 / 32.0);
	lightCheck(at_midBlock, mc_Entity);  

	vec4 viewpos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec4 modelPos = gl_ModelViewMatrix * gl_Vertex;
	vec4 position = viewpos;
	position.xyz += cameraPosition.xyz;

	normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
	normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space
	blockID = int(mc_Entity.x);
	float frames = float(frameCounter);
	vec4 noise = texture(noisetex,position.xy);
	float offset = (float((sin(frames * (0.01))))/5) * (noise.r* 2 - 1.);
	//float frames = float(frameCounter)/7000;
	vec4 extraNoise = texture(noisetex, (position.xz * vec2(0.1) + vec2(frames/7000))) * (1.0 + (rainStrength * 2.));
	switch(blockID){
		case 8: //leaves
			//gl_Position.y
			//vec4 position = vec4(0); 
			float totalOffset = (offset * clamp(modelPos.y,-1,1)) * (1. + rainStrength) + offset/2;
			position.x += extraNoise.r/15 + totalOffset;
			position.z -= extraNoise.r/16;
			//position.x = min(1.0, position.x);
			//position.z += offset;
			
			//gl_Position.xyz /= gl_Position.w;

		break;
		case 9:
		position.x += offset /2 * (max((modelPos.y * 2),2)) + extraNoise.r/20;
		break;
		case 10:
		position.x += (extraNoise.r/10 + offset * 2);
	}
	position.xyz -= cameraPosition.xyz;
	gl_Position = (gl_ProjectionMatrix * gbufferModelView * position);
	glcolor = gl_Color;
}

//terrain_solid: io.github.douira.glsl_transformer.parser.ParsingException: Unexpected token ')'
//