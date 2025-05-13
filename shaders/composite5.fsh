#version 430 compatibility
#define BLOOM //bloom effect

uniform sampler2D colortex0;

in vec2 texcoord;
out vec4 color;

const float Pi = 6.28318530718; // Pi*2
    
    // GAUSSIAN BLUR SETTINGS {{{
const float Directions = 10.0; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
const float Quality = 2.0; // BLUR QUALITY (Default 4.0 - More is better but slower)

//https://www.shadertoy.com/view/Xltfzj
void main() { 
    #ifdef BLOOM
	color = texture(colortex0, texcoord);
    vec4 newColor = color;
    // float waterMask = texture(colortex6, texcoord).g;
    // vec3 encodedNormal = texture(colortex2, texcoord).rgb;
	// vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
    // float depth = texture(depthtex0, texcoord).r;
    // vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	// vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    // GAUSSIAN BLUR SETTINGS }}}
   
    vec2 Radius = vec2(0.01);
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = texcoord;
    // Pixel colour
    
    // Blur calculations
    for( float d=0.0; d<Pi; d+=Pi/Directions)
    {
		for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality)
        {
			newColor += texture(colortex0, uv+vec2(cos(d),sin(d))*Radius*i);		
        }
    }
    
    // Output to screen
    newColor /= Quality * Directions - 15.0;
    float brightness = (newColor.x + newColor.y + newColor.z)/3;
    color.rgb += newColor.rgb * 0.02;
    #endif

    #ifndef BLOOM
    color = texture(colortex0,texcoord);
    #endif
}

//composite5.fsh: composite5.fsh: 0(58) : error C7011: implicit cast from "float" to "vec2"

