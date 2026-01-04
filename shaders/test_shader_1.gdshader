shader_type canvas_item;

uniform vec2 virtual_resolution = vec2(512.0, 512.0);

void vertex()
{
	// Called for every vertex the material is visible on.
}

void fragment()
{
	COLOR = vec4(UV, 0.0, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
