shader_type canvas_item;
render_mode unshaded;

uniform sampler2D src_tex;

void vertex()
{
	// Called for every vertex the material is visible on.
}

void fragment()
{
	vec3 col = texture(src_tex, vec2(UV.x, UV.y)).rgb;
    COLOR = vec4(col, 1.0);
	//COLOR = vec4(UV.x, 0.0, 0.0, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
