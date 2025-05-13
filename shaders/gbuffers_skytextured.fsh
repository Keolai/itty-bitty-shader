#version 430 compatibility

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec4 glcolor;

uniform int biome_category;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	if (color.a < alphaTestRef) {
		discard;
	}
	if (biome_category == CAT_THE_END){ //the end is fucked up
	color.rgb = vec3(0,0,0);
	}
}