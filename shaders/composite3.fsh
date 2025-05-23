#version 430 compatibility
#include /lib/distort.glsl
#include /lib/dayCycle.glsl
#include /colors/fogColors.glsl

#define FOG_DENSITY 5.0

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform float far; 
uniform int worldTime;
uniform vec3 shadowLightPosition;
uniform bool hasSkylight;
uniform sampler2D noisetex;


uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform int biome_category;
uniform int biome;
uniform float rainStrength;
uniform vec3 fogColor;
uniform vec3 skyColor;

uniform int isEyeInWater;


in vec2 texcoord;

const float uFogDensity = 0.07;
const float uFogHeight = 5.; //really?


vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

/* RENDERTARGETS: 0,5*/
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 oldFog; 

vec3 getFogColor(float time, int biome){
  switch (biome) {
    case BIOME_THE_END: case BIOME_END_HIGHLANDS: case BIOME_END_MIDLANDS: case BIOME_END_BARRENS: case BIOME_SMALL_END_ISLANDS:
      return endFogColor;
    break;
      case BIOME_NETHER_WASTES:
      return netherFogColor;
    break;
      case BIOME_WARPED_FOREST:
      return warpedForestColor;
    break;
      case BIOME_CRIMSON_FOREST:
      return crimsonForestColor;
    break;
    case BIOME_SOUL_SAND_VALLEY:
      return soulSandValleyColor;
    break;
    case BIOME_BASALT_DELTAS:
      return basaltDeltaColor;
    break;
    case BIOME_OCEAN: case BIOME_DEEP_OCEAN: case BIOME_LUKEWARM_OCEAN: case BIOME_WARM_OCEAN:
    case BIOME_BEACH:
      return oceanfogColor;
    break;
    case BIOME_FROZEN_OCEAN: case BIOME_DEEP_FROZEN_OCEAN: case BIOME_DEEP_COLD_OCEAN:
      return coldoceanfogColor;
    break;

    // case CAT_NETHER:
    // return netherFogColor;

    // break;
    // case CAT_THE_END:
    // return endFogColor;
    // break;
    }
	float dayNightMix = dayOrNight(time);
  vec3 fog = mix(nightFogColor, dayfogColor, dayNightMix);
	return mix(fog, rainfogColor, rainStrength);

}

void main() { //fog
  color = texture(colortex0, texcoord);
  vec3 oldFogColor = texture(colortex5, texcoord).rgb;
  float dayOrNightVal = dayOrNight(float(worldTime));

  vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

  float depth = texture(depthtex0, texcoord).r;
  float originalDepth = depth;
  float waterMask = texture(colortex6,texcoord).g;
  float waterDepth = texture(depthtex1,texcoord).r;
  depth = max(depth, waterDepth);
  if(((depth == 1.0 && waterMask != 1.)&& isEyeInWater==0 && biome_category != CAT_NETHER)){
    return;
  }


  //composite3.fsh: composite3.fsh: 0(112) : error C1503: undefined variable "colortex6"


    vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos); //viewspace
    float dist = length(viewPos) / far;

    vec3 topNDCPos = vec3(texcoord.xy, originalDepth) * 2.0 - 1.0;
    vec3 topviewPos = projectAndDivide(gbufferProjectionInverse, topNDCPos); //viewspace
    float topdist = length(topviewPos) / far;
    float fogFactor = exp(-FOG_DENSITY * (1.0 - dist));
    vec3 uCameraView = (gbufferModelViewInverse * vec4(viewPos,1.0)).xyz + cameraPosition;//worldpos
    vec4 noiseFactor = texture(noisetex,uCameraView.xz * vec2(0.01));
    vec3 newFogColor = getFogColor(float(worldTime), biome);
    float fogColorDistance = distance(newFogColor, oldFogColor); //fix
    vec3 mixedFog = mix(newFogColor,oldFogColor, fogColorDistance); 
    vec3 sunOrMoonFog = mix(moonColor,sunColor,dayOrNightVal);
  
    oldFog = vec4(mixedFog,1.0);
    vec3 fogOrigin = cameraPosition;
    vec3 fogDirection = normalize(uCameraView - fogOrigin);
    float fogDepth = distance(uCameraView,cameraPosition);
    float heightFogFactor = uFogHeight * exp(-fogOrigin.y * uFogDensity) * (1.0 - exp(-fogDepth * fogDirection.y * uFogDensity)) / fogDirection.y;
     float sunAmount = max(dot(fogDirection,worldLightVector),0.0);
    float proxDepth = clamp(dist * 1.5, 0., 1.0);
    mixedFog *= eyeWaterColors[isEyeInWater];
    mixedFog = mixedFog * (1 - waterMask) + mix(nightWaterFog,waterFogColor,dayOrNight(float(worldTime))) * waterMask;
    mixedFog = mix(mixedFog,sunOrMoonFog,sunAmount * float(hasSkylight) * min((1.1 - waterMask),1.0)); //turn off for water?
    if (isEyeInWater > 1){
      mixedFog = eyeWaterColors[isEyeInWater];
    }
    float extraFog = min((dist * 2),((dist * rainStrength) + (dist * min(isEyeInWater,1.0)) + dist * (1 - dayOrNightVal)/7. + (dist/2 * waterMask)));
    extraFog += (dist * rainStrength);
    float finalFogFactor = clamp(heightFogFactor * proxDepth + extraFog, 0.0, 1.0);
    color.rgb = mix(color.rgb,mixedFog, finalFogFactor);
    color.rgb = mix(color.rgb, skyColor, waterMask * topdist);
//color.rgb = vec3(heightFogFactor);
}

//composite2.fsh: composite2.fsh: 0(73) : error C1503: undefined variable "fogColorDistance"
//composite2.fsh: composite2.fsh: 0(74) : error C7011: implicit cast from "float" to "vec3"
//composite2.fsh: composite2.fsh: 0(77) : error C1503: undefined variable "rainFogColor"
//composite2.fsh: composite2.fsh: 0(105) : error C1503: undefined variable "shadowLightPosition"


