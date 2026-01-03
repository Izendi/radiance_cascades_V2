shader_type canvas_item;
render_mode unshaded;

uniform vec2 virtual_resolution = vec2(1024.0, 1024.0);

uniform sampler2D src_tex;



void vertex()
{
	// Called for every vertex the material is visible on.
}

void fragment()
{
	//vec2 scale = vec2(512.0 / 1024.0, 512.0 / 1024.0);
	//
	//vec3 col = texture(src_tex, vec2(UV.x * scale.x, UV.y * scale.y)).rgb;
	
	vec3 col = texture(src_tex, vec2(UV.x, UV.y)).rgb;
	
	COLOR = vec4(col, 1.0);
	//COLOR = vec4(UV.x, 0.0, 0.0, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
