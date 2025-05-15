#version 430 compatibility
#include /lib/raytrace.glsl
#include /lib/dayCycle.glsl

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D depthtex1;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 viewNormal;
in vec3 modelPos;


uniform vec3 shadowLightPosition;
uniform int worldTime;
// uniform mat4 gbufferModelViewInverse;
// uniform mat4 gbufferProjectionInverse;

const vec3 sunColor = vec3(1.);
const vec3 moonColor = vec3(0.29, 0.58, 0.749);

/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 cloudMap; //cloud mask


vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

void main() {
	color = texture(gtexture, texcoord) * glcolor; //biome tint
	if (color.a < alphaTestRef) {
		discard;
	}
	
	color *= texture(lightmap, lmcoord); //lightmap
	float depth = texture(depthtex1, texcoord).r;
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);

	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
	vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos + cameraPosition;
	vec3 direction = normalize(worldPos.xyz - cameraPosition);
	float sunAmount = max(dot(direction,worldLightVector),0.0);
	 float dayOrNightVal = dayOrNight(float(worldTime));
	vec3 sunOrMoonFog = mix(moonColor,sunColor,dayOrNightVal);
	color.rgb = mix(color.rgb,sunOrMoonFog,sunAmount);
	// vec3 inverseNormal = -1 * normalize(viewNormal);
    // vec3 viewVect = normalize(worldPos.xyz);
    // vec3 rayDirection = worldPos.xyz;
	// float dist = 0.0;
	// vec2 rayCast = raytrace(worldPos.xyz,rayDirection,50,dist);
	// //color.rgb = vec3(depth/2);
	// //color.a = 1;
	//

	// float alpha = dot(normal, worldLightVector); //light value

	// //color.rgb = normal; //write normals to color
	// //color.a = 1 - alpha;
	// //color.rgb = vec3(alpha);
	lightmapData = vec4(lmcoord, 0.0, 1.0);
	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
	cloudMap = vec4(0,1,0,1);
	//color.rgb = texture(depthtex0,texcoord).rgb;
	//color = encodedNormal;
}
//