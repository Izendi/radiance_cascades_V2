shader_type canvas_item;
render_mode unshaded;

uniform vec2 virtual_resolution = vec2(1024.0, 1024.0);

uniform sampler2D src_tex;

// Old more intuative simple version:
vec3 DrawGrid(vec3 color, vec2 uv_coords, vec2 resolution, vec3 lineColor, float cellSpacing)
{
	vec2 center = uv_coords - 0.5;
	vec2 cells = abs(fract(center * resolution / vec2(cellSpacing)) - 0.5);
	float distToEdge = (1.0 - 2.0 * max(cells.x, cells.y));
	float lines = smoothstep(0.0, 0.05, distToEdge);

	color = mix(lineColor, color, lines);

	return color;

}

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
