#version 430 compatibility
#include /lib/raytrace.glsl

#define REFLECTIONS

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
// uniform sampler2D colortex6;
uniform sampler2D colortex4;

in vec2 texcoord;
uniform vec3 skyColor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

float screenDistance(vec2 start, vec2 end){
    float xDif = start.x - end.x;
    float yDif = start.y - end.y;

    return sqrt(pow(xDif,2.) + pow(yDif,2.))/2;
}

void main() { //this controlls the light stuf
#ifdef REFLECTIONS
	color = texture(colortex0, texcoord);
    float waterMask = texture(colortex6, texcoord).g;
    vec3 encodedNormal = texture(colortex2, texcoord).rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
    vec3 viewSpaceNormal = (normal) * mat3(gbufferModelView);
    float depth = texture(depthtex0, texcoord).r;
    vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    vec4 worldPos = gbufferModelViewInverse * vec4(viewPos, 1.0);
    vec3 viewVect = normalize(worldPos.xyz);
    vec3 rayDirection = normalize(reflect(viewVect, normal));
    float dist = 0;
    //float screenDist = screenDistance(vec2(0.5),texcoord);
    //vec3 hitPos = vec3(0.);
    if (waterMask == 1){ //only reflect on water
       vec2 reflectionUV = raytrace(worldPos.xyz,rayDirection,50,dist);
       if (reflectionUV.x > 0.1){
        color = mix(color,texture(colortex0,reflectionUV),0.2);
       }
    }
   // color.rgb = vec3(viewVect.y)
#endif
#ifndef REFLECTIONS
    color = texture(colortex0, texcoord);
#endif

}



