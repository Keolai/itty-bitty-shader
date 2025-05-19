#version 430 compatibility
#include /lib/distort.glsl

#define SHADOW_QUALITY 2
#define SHADOW_SOFTNESS 1
#define SUNRISE 23215
#define SUNSET 12785
#define MAX_TIME 23999

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform int heldItemId;
uniform int heldItemId2;
uniform float far; 

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;

uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

const int shadowMapResolution = 2048;

in vec2 texcoord;
in vec3 mc_Entity;

/* RENDERTARGETS: 0,1,3,4,9 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 blueLightData; //3
layout(location = 3) out vec4 colorLightMap;
layout(location = 4) out vec4 skyMap; //4



vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}



void main() { //this controls altering light map
	color = texture(colortex0, texcoord);

	float depth = texture(depthtex0, texcoord).r;
	skyMap = vec4(vec3(float (depth == 1.)),1.0);
	if (depth == 1.0) {
  		return;
	}



	vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g component
	vec2 bluelightmap = texture(colortex3, texcoord).rg; 

	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	 float dist = length(viewPos) / far; //change to get depth from player 0 is close
	vec3 playerPosLight = feetPlayerPos + cameraPosition;
	float heldLight = max(float(heldBlockLightValue),float(heldBlockLightValue2));
	float lightDistance = length(playerPosLight);
	float light = max((pow(1- dist,15) * heldLight/18),lightmap.r);
	lightmap.r = light;
	colorLightMap = texture(colortex4,texcoord);
	//color.rgb = texture(colortex4,texcoord).rgb;
	

	lightmapData = vec4(lightmap, 0.0, 1.0);
	blueLightData = vec4(bluelightmap, 0.0, 1.0);
	
	//color.rgb = vec3(lightDistance);
}

//composite1.fsh: composite1.fsh: 0(124) : error C1503: undefined variable "lightMap"



