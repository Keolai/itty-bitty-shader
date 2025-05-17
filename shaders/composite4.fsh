#version 430 compatibility
#include /lib/distort.glsl
#include /lib/dayCycle.glsl

#define GODRAYS

#define SHADOW_QUALITY 2
#define SHADOW_SOFTNESS 1
#define SUNRISE 23215
#define SUNSET 12785
#define MAX_TIME 23999
#define ITERATIONS 10

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex9;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform float far; 

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform int biome_category;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 eyePosition;
uniform float viewHeight;
uniform float viewWidth;
uniform sampler2D colortex10;
uniform int frameCounter;
uniform float rainStrength;
uniform bool hasSkylight;

const int shadowMapResolution = 2048;
const int nsamples = 20;
const vec3 sunlightColor = vec3(1, 0.976, 0.863);
const vec3 nightColor = vec3(0.349, 0.529, 0.8);


in vec2 texcoord;
uniform int worldTime;

/* RENDERTARGETS: 0,3 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 rawRay;


vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

vec4 getNoise(vec2 coord){
  ivec2 screenCoord = ivec2(coord * vec2(viewWidth, viewHeight)); // exact pixel coordinate onscreen
  ivec2 noiseCoord = screenCoord % 256; // wrap to range of noiseTextureResolution
  return texelFetch(colortex10, noiseCoord, 0);
}

vec3 getSunlightColor(float time){
	float dayNightMix = sin(time/3694.78); //1 is daytime, -1 is night time
	dayNightMix = (dayNightMix/2.0) + 0.5;
	return mix(nightColor, sunlightColor, dayNightMix);

}

float screenDistance(vec2 start, vec2 end){
    float xDif = start.x - end.x;
    float yDif = start.y - end.y;

    return sqrt(pow(xDif,2.) + pow(yDif,2.))/2;
}



void main() { //this controlls the initial godray
#ifdef GODRAYS
	color = texture(colortex0, texcoord);
    float depth = texture(depthtex0, texcoord).r;
    vec3 lightmap = texture(colortex1,texcoord).rgb;
   // vec4 skyMap = vec4(vec3(float (depth == 1.)),1.0);
    //skyBuffer = skyMap;
   // 
    //vec3 lightVector = normalize(shadowLightPosition);
	vec4 clipLightVector = gbufferProjection * vec4(shadowLightPosition,1.0);
    vec3 ndcLight = clipLightVector.xyz / clipLightVector.w;
    vec3 screenLight = ndcLight * 0.5 + 0.5;
    vec2 center = screenLight.xy;
	float blurStart = 0.5;
    float blurWidth = 0.5;
    float noise = getNoise(texcoord).r;
    vec3 lightColor = getSunlightColor(float(worldTime));
    float dayNight = dayOrNight(float(worldTime));
    float sunsetTimer = getSunset(float(worldTime));
    float dis = screenDistance(center,texcoord);
    
	vec2 uv = texcoord.xy;
    
    uv -= center;
    float precompute = blurWidth * (1.0 / float(nsamples - 1));
    
    vec4 preColor = vec4(0.0);
    for(int i = 0; i < nsamples; i++)
    {
        float scale = blurStart + (float(i)* precompute);
        preColor += texture(colortex9, uv * scale + center) * vec4(noise/4 + 0.75);
    }
   // Blur(texcoord, 0.5);
    
    preColor /= float(nsamples);
    vec3 addColor = (preColor.rgb *lightColor * vec3(max(dayNight,0.01) * dayNight))/4;
    float rain = float(min(rainStrength,1) == 0);
	float rayVal = addColor.r * rain * max((1. - dis),0) * float(hasSkylight);
    vec4 rayBuffer = texture(colortex3,texcoord);
    rawRay = vec4(rayBuffer.xy,rayVal * (1 - dis * 1.5),1.0); //write back to colortex;

    //color.rgb = vec3(1 - dis);
#endif
#ifndef GODRAYS
    color = texture(colortex0, texcoord);
#endif
	//color.rgb = vec3(lightDistance);
}

//
//composite1.fsh: composite1.fsh: 0(124) : error C1503: undefined variable "lightMap"
//sky_textured: sky_textured: 0(32) : error C1503: undefined variable "lightData"
//


