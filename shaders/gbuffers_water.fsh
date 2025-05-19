#version 430 compatibility
#include /colors/lightingColors.glsl

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D depthtex0;
uniform sampler2D colortex4;

uniform float alphaTestRef = 0.1;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in float offset;
in vec3 noise;
in vec3 entity;


/* RENDERTARGETS: 0,1,2,6,7,4 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData; //yellow light sources 
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 specularity;
layout(location = 4) out vec4 waterMask;
layout(location = 5) out vec4 colorLight;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	color *= texture(lightmap, lmcoord);
	float depth = texture(depthtex0, texcoord).r;
	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
	//float specular = dot(normal, worldLightVector); //issue
	//color += clamp(specular,0,1);
	if (entity.x == 7){
		specularity = vec4(clamp(offset - 0.4,0.0,1.0) * 6,1,0,1) ;//issue for ice
	} else {
		specularity = vec4(0,1,0,1);
	}

	if (entity.x == 3){
		colorLight = vec4(purpleColor.rgb,1.); //big ISSUE
	}
	waterMask = vec4(1.0,0.0,0.0,0.0);
		color.a *= 0.4;
		//color.rgb += vec3(max(0.0, offset - 0.5) * 2);
	//vec3 specColor = specular;
	//color.rgb += vec3(offset/4);
	//color.gb += vec2(offset/5);
	//color.rgb = vec3(clamp(specular,0,1));
	if (color.a < alphaTestRef) {
		discard;
	}
	lightmapData = vec4(lmcoord, 0.0, 1.0);
	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
	//color.rgb = normal.rgb;
	//color = waterMask;
	//color = specularity;
}

//terrain_translucent: terrain_translucent: 0(42) : error C7011: implicit cast from "float" to "vec3"
