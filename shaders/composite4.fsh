#version 430 compatibility
#include /lib/distort.glsl

#define SHADOW_QUALITY 2
#define SHADOW_SOFTNESS 1
#define SUNRISE 23215
#define SUNSET 12785
#define MAX_TIME 23999

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

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 eyePosition;
uniform float viewHeight;
uniform float viewWidth;

const int shadowMapResolution = 2048;
const int nsamples = 20;


in vec2 texcoord;

/* RENDERTARGETS: 0,9 */
layout(location = 0) out vec4 color;


vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}



void main() { //this controlls the light stuf
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
    vec3 screenPos = screenLight * vec3(viewWidth,viewHeight,1.0);
    vec2 center = screenLight.xy;
	float blurStart = 1.0;
    float blurWidth = 0.5;

    
	vec2 uv = texcoord.xy;
    
    uv -= center;
    float precompute = blurWidth * (1.0 / float(nsamples - 1));
    
    vec4 preColor = vec4(0.0);
    for(int i = 0; i < nsamples; i++)
    {
        float scale = blurStart + (float(i)* precompute);
        preColor += texture(colortex9, uv * scale + center);
    }
    
    
    preColor /= float(nsamples);
    
	color.rgb += preColor.rgb/4;
    //color.rgb = skyMap.rgb;
	
	//color.rgb = vec3(lightDistance);
}

//
//composite1.fsh: composite1.fsh: 0(124) : error C1503: undefined variable "lightMap"
//sky_textured: sky_textured: 0(32) : error C1503: undefined variable "lightData"



