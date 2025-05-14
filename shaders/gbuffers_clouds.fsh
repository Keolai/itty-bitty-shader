#version 430 compatibility
//#include /lib/raytracer.glsl

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D depthtex0;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 viewNormal;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;

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
	float depth = texture(depthtex0, texcoord).r;
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);


	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
	vec3 inverseNormal = -1 * normalize(viewNormal);

	float alpha = dot(normal, worldLightVector); //light value

	//color.rgb = normal; //write normals to color
	//color.a = 1 - alpha;
	color.rgb = vec3(alpha);
	lightmapData = vec4(lmcoord, 0.0, 1.0);
	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
	//color = encodedNormal;
}