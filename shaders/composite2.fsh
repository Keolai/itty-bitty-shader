#version 430 compatibility
#include /lib/distort.glsl
#include /lib/dayCycle.glsl
#include /colors/lightingColors.glsl

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
uniform sampler2D colortex6;
uniform sampler2D colortex7;

uniform int isEyeInWater;
uniform int biome_category;

uniform int heldItemId;

uniform float far; 
uniform int worldTime;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;

uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 eyePosition;
uniform float ambientLight;
uniform bool hasSkylight;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 getSunlightColor(float time){
	float dayNightMix = sin(time/3694.78); //1 is daytime, -1 is night time
	dayNightMix = (dayNightMix/2.0) + 0.5;
  if (biome_category == CAT_ICY){
    return mix(nightColor, coldBiomeSun, dayNightMix);
  }
	return mix(nightColor, sunlightColor, dayNightMix);

}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

vec3 getShadow(vec3 shadowScreenPos){
  float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r); // sample the shadow map containing everything

  /*
  note that a value of 1.0 means 100% of sunlight is getting through
  not that there is 100% shadowing
  */

  if(transparentShadow == 1.0){
    /*
    since this shadow map contains everything,
    there is no shadow at all, so we return full sunlight
    */
    return vec3(1.0);
  }

  float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r); // sample the shadow map containing only opaque stuff

  if(opaqueShadow == 0.0){
    // there is a shadow cast by something opaque, so we return no sunlight
    return shadowColorBl;
  }

  // contains the color and alpha (transparency) of the thing casting a shadow
  vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);


  /*
  we use 1 - the alpha to get how much light is let through
  and multiply that light by the color of the caster
  */
  return shadowColor.rgb * (1.0 - shadowColor.a);
}

vec3 getSoftShadow(vec4 shadowClipPos){
  const float range = SHADOW_SOFTNESS / 2.0; // how far away from the original position we take our samples from
  const float increment = range / SHADOW_QUALITY; // distance between each sample

  vec3 shadowAccum = vec3(0.0); // sum of all shadow samples
  int samples = 0;

  for(float x = -range; x <= range; x += increment){
    for (float y = -range; y <= range; y+= increment){
      vec2 offset = vec2(x, y) / shadowMapResolution; // we divide by the resolution so our offset is in terms of pixels
      vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0); // add offset
      offsetShadowClipPos.z -= 0.001; // apply bias
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
      vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
      shadowAccum += getShadow(shadowScreenPos); // take shadow sample
      samples++;
    }
  }

  return shadowAccum / float(samples); // divide sum by count, getting average shadow
}

void main() {
	color = texture(colortex0, texcoord);
	color.rgb = pow(color.rgb, vec3(2.2));

	float depth = texture(depthtex0, texcoord).r;
	if (depth == 1.0) {
  		return;
	}
	
  vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
   // float dayCycle = dayOrNight(float(worldTime));


	vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g components
    vec2 blueMap = texture(colortex3, texcoord).rg;
    vec2 purpleMap = texture(colortex4, texcoord).rg;
	vec3 encodedNormal = texture(colortex2, texcoord).rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length

	vec3 skylight = lightmap.g * skylightColor;
	vec3 ambient = ambientColor * ambientLight;
	//vec3 sunlight = sunlightColor * clamp(dot(worldLightVector, normal), 0.0, 1.0) * lightmap.g;

	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	 float dist = length(viewPos) / far; //change to get depth from player 0 is close
	vec3 blocklight = lightmap.r * blocklightColor * 0.5; //torches 
    vec3 blueLight = blueMap.r * blueLightColor;
    vec3 purpLight = purpleMap.r * purpleLightColor;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	vec3 currentSunlight = getSunlightColor(float(worldTime));
	vec3 shadow = getSoftShadow(shadowClipPos) * (1 - (dist * 1.5));
  float waterMask = texture(colortex6, texcoord).g;
	vec3 sunlight = clamp(currentSunlight * dot(normal, worldLightVector) * shadow,vec3(0.0),vec3(1.));
    sunlight += max(getSunset(float(worldTime)) - 0.5,0.) * sunsetColor; //sunset
    color.rgb += sunlight * clamp((min(pow(texture(colortex6,texcoord).r * 1.2,10),1.0) *(1- (depth)) * 4),0,1) * shadow; //water highlights
	  color.rgb *= blocklight + skylight + ambient + sunlight*float(1.) + blueLight + purpLight;
    color.rgb *= eyeWaterColors[isEyeInWater];
    //color.rgb = texture(colortex3,texcoord).rgb; cloud and bluelight
  //color.rgb = normal.rgb;
}
//terrain_solid: terrain_solid: 0(48) : error C1503: undefined variable "blueLighData"
