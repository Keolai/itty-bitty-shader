#version 430 compatibility
#include /lib/distort.glsl
#include /lib/dayCycle.glsl
#include /colors/lightingColors.glsl
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

const int nsamples = 20;


in vec2 texcoord;
uniform int worldTime;

const float Pi = 6.28318530718; // Pi*2
    
    // GAUSSIAN BLUR SETTINGS {{{
const float Directions = 8.0; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
const float Quality = 3.0; // BLUR QUALITY (Default 4.0 - More is better but slower)

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



void main() { //this controlls the light stuf
#ifdef GODRAYS
	float ray = texture(colortex3, texcoord).b;
    color = texture(colortex0,texcoord);
    float newColor = ray;
    vec3 lightColor = getSunlightColor(float(worldTime));
    // float waterMask = texture(colortex6, texcoord).g;
    // vec3 encodedNormal = texture(colortex2, texcoord).rgb;
	// vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
    // float depth = texture(depthtex0, texcoord).r;
    // vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	// vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    // GAUSSIAN BLUR SETTINGS }}}
   
    vec2 Radius = vec2(0.01);
    float dis = screenDistance(vec2(0.5),texcoord);
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = texcoord;
    // Pixel colour
    
    // Blur calculations
    for( float d=0.0; d<Pi; d+=Pi/Directions)
    {
		for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality)
        {
			newColor += texture(colortex3, uv+vec2(cos(d),sin(d))*Radius*i).b;		
        }
    }
    
    // Output to screen
    newColor /= Quality * Directions - 15.0;
    //float brightness = (newColor.x + newColor.y + newColor.z)/3;
    color.rgb += vec3(newColor / 3) * getSunlightColor(float(worldTime));
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


