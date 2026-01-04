shader_type canvas_item;

uniform vec2 virtual_resolution = vec2(512.0, 512.0);

//uniform float total_elapsed_time;

//Gets the t value for a lerp given two points and a value between them
float inverseLerp(float point, float minValue, float maxValue)
{
	return (point - minValue) / (maxValue - minValue);
}

//Takes a point between two value and maps it to another point
float remap(float point, float minValue, float maxValue, float newMinValue, float newMaxValue)
{
	float t = inverseLerp(point, minValue, maxValue);
	return mix(newMinValue, newMaxValue, t); //mix == lerp
}

vec3 BackgroundColor(vec2 uv_coords)
{
	float distFromCenter = length(abs(uv_coords - 0.5));
	float vignette = 1.0 - distFromCenter;
	vignette = smoothstep(0.0, 0.7, vignette);
	vignette = remap(vignette, 0.0, 1.0, 0.3, 1.0);
	return vec3(vignette);
}


vec3 DrawGrid(vec3 color, vec2 uv_coords, vec2 resolution, vec3 lineColor, float cellSpacing, float lineWidth)
{
	vec2 center = uv_coords - 0.5;
	vec2 cells = abs(fract(center * resolution / cellSpacing) - 0.5);
	float distToEdge = (0.5 - max(cells.x, cells.y)) * cellSpacing;
	float lines = smoothstep(0.0, lineWidth, distToEdge);

	color = mix(lineColor, color, lines);

	return color;

}

float sdfCircle(vec2 p, float r)
{
	return length(p) - r;
}

float sdRoundedX( in vec2 p, in float w, in float r )
{
    p = abs(p);
    return length(p-min(p.x+p.y,w)*0.5) - r;
}

vec2 rotate(vec2 p, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	return vec2(
		p.x * c - p.y * s,
		p.x * s + p.y * c
		);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment()
{
	//float x_res = 1.0 / SCREEN_PIXEL_SIZE.x;
	//float y_res = 1.0 / SCREEN_PIXEL_SIZE.y;

	vec2 resolution = vec2(virtual_resolution.x, virtual_resolution.y);

	vec2 NDC_coord = UV * 2.0 - 1.0;

	vec2 centeredPixelCoords = (UV - 0.5) * resolution; // (0, 0) is is the middle but the x and y legth is the resolution. e.g -250 to 250 x and -100 to 100 y
	centeredPixelCoords.x = -centeredPixelCoords.x;
	centeredPixelCoords.y = -centeredPixelCoords.y;

	//I need to flip these or the coordinates don't seem to match up. Maybe a quirk of godot
	// or I am misunderstanding something.
	NDC_coord.y = -NDC_coord.y;
	NDC_coord.x = -NDC_coord.x;

	vec3 finalColor = BackgroundColor(UV);

	finalColor = DrawGrid(finalColor, UV, resolution, vec3(0.0), 10.0, 1.00);
	finalColor = DrawGrid(finalColor, UV, resolution, vec3(0.0), 100.0, 2.00);

	float d = sdfCircle(centeredPixelCoords, 100.0);

	centeredPixelCoords = rotate(vec2(centeredPixelCoords.x + 100.0, centeredPixelCoords.y + 50.0), TIME);
	//centeredPixelCoords = rotate(centeredPixelCoords, 23);

	float d2 = sdRoundedX(centeredPixelCoords, 200.0, 25.0);

	finalColor = mix(vec3(0.8, 0.1, 0.1), finalColor, step(0.0, d2));

	COLOR = vec4(finalColor, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
