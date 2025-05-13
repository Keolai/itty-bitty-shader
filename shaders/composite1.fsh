#version 430 compatibility
#include /lib/distort.glsl
#include /lib/raytracer.glsl

#define REFLECTIONS

#define SHADOW_QUALITY 2
#define SHADOW_SOFTNESS 1
#define SUNRISE 23215
#define SUNSET 12785
#define MAX_TIME 23999
#define ITERATIONS 10

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex6;
uniform sampler2D colortex4;
//uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform float far; 

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform int biome_category;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
//uniform mat4 gbufferProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 eyePosition;
uniform float viewHeight;
uniform float viewWidth;
uniform int frameCounter;
uniform float rainStrength;
uniform vec3 cameraPosition;

//https://github.com/FatemehAmereh/SSR/blob/master/Shaders/SSRFS.fs
// Consts should help improve performance

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

void main() { //this controlls the light stuf
#ifdef REFLECTIONS
	color = texture(colortex0, texcoord);
    float waterMask = texture(colortex6, texcoord).g;
    vec3 encodedNormal = texture(colortex2, texcoord).rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
    vec3 viewSpaceNormal = (encodedNormal - cameraPosition) * mat3(gbufferModelView);
    float depth = texture(depthtex0, texcoord).r;
    vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    vec3 viewVect = normalize(viewPos);
    vec3 rayDirection = reflect(viewVect, viewSpaceNormal);
    vec3 hitPos = vec3(0.);
    if (waterMask == 1){ //only reflect on water
       bool hit = raytrace(viewPos,rayDirection,10,1,hitPos);
       if (hit){
        vec2 colorCoords = hitPos.xy;
        color.rgb = mix(color.rgb,texture(colortex0,colorCoords).rgb,0.5);
        //color.rgb = vec3(0.);
       }
    }
   // color.rgb = vec3(viewVect.y)
#endif
#ifndef REFLECTIONS
    color = texture(colortex0, texcoord);
#endif
    //color.rgb = vec3(1 - dis);
	
	//color.rgb = vec3(lightDistance);
}
//composite1.fsh: composite1.fsh: 0(26) : error C1503: undefined variable "gbufferProjection"
//composite1.fsh: composite1.fsh: 0(83) : error C1503: undefined variable "projectAndDivide"
//


