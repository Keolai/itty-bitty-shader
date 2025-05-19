#version 430 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform float far;
//uniform sampler2D depthtex0;
#include /lib/cl/common.glsl
#include /colors/lightingColors.glsl


uniform int blockEntityId;
uniform float alphaTestRef = 0.1;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
flat in int blockID;
// uniform vec3 cameraPosition;

in fragment_data {
    vec2 textureCoord;
    vec2 lightMapCoord;
    vec4 glColor;

    vec3 worldPos;
    flat ivec3 localChunkPos;
} data;

/* RENDERTARGETS: 0,1,2,3,4 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData; //yellow light sources 
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 blueLightData; //4
layout(location = 4) out vec4 colorLightData; //6

void main() {
	color = texture(gtexture, texcoord) * glcolor; //biome tint
	//color *= texture(lightmap, lmcoord); //lightmap
	//vec4 startLight = texture(lightmap, data.lightMapCoord);
	float heldLight = max(float(heldBlockLightValue),float(heldBlockLightValue2));
	float dist = length(data.worldPos - cameraPosition);
	//startLight.rgb = max(vec3(pow((far - dist)/(far),19) * heldLight/15),startLight.rgb);
    //color = applyColouredLight(color, startLight, data.worldPos, data.localChunkPos); //this is causing perf issues
	color *= texture(lightmap, lmcoord); //lightmap
	if (color.a < alphaTestRef) {
		discard;
	}
	//color.rgb = data.worldPos - cameraPosition;
	//int blockId = int(mc_Entity.x);
	//colorLightData = vec4(1.);
	switch (blockID){
		case 5: //yellow
		colorLightData = vec4(warmColor,1.);
		break;
		case 6:
		colorLightData = vec4(blueColor,1.);
		break;
		default:
		colorLightData = vec4(0,0,0,1);
		break;
	}
	lightmapData = vec4(lmcoord, 0.0, 1.0);
	//color.rgb = normal; //write normals to color
	//color.rgb = vec3(blockID); 
	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
	//color.rgb = texture(depthtex0,texcoord).rgb/2.;
	//color = encodedNormal;
}

//Shader compilation failed, see log for details
//terrain_solid: terrain_solid: 0(53) : error C1503: undefined variable "blockId"
//TERRAIN_SOLID: TERRAIN_SOLID: Fragment inf




