shader_type canvas_item;

const vec3 BLACK = vec3(0.0, 0.0, 0.0);
const vec3 WHITE = vec3(1.0, 1.0, 1.0);
const vec3 GREY = vec3(0.6, 0.6, 0.6);

float inverseLerp(float v, float minValue, float maxValue) 
{
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) 
{
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

vec3 BackgroundColor(vec2 texCoords)
{
    float distFromCenter = length(abs(texCoords - 0.5));

    float vignette = 1.0 - distFromCenter;

    vignette = smoothstep(0.0, 0.7, vignette);
    vignette = remap(vignette, 0.0, 1.0, 0.3, 1.0);

    return vec3(vignette);
}

vec3 drawGrid(vec2 texCoord, vec3 color, vec3 lineColor, float cellSpacing, float lineWidth)
{
    vec2 resolution = vec2(800, 600);
    vec2 center = texCoord - 0.5;
    vec2 cells = abs(fract(center * resolution / cellSpacing) - 0.5);
    float distToEdge = (0.5 - max(cells.x, cells.y)) * cellSpacing;
    float lines = smoothstep(0.0, lineWidth, distToEdge);

    color = mix(lineColor, color, lines);

    return color;
}

void vertex() 
{
	// Called for every vertex the material is visible on.
}

void fragment() 
{
	vec3 backgroundColor = vec3(1.0, 1.0, 1.0);
	backgroundColor = drawGrid(UV, backgroundColor, BLACK, 100.0, 1.5);
	backgroundColor = drawGrid(UV, backgroundColor, GREY, 10.0, 1.0);
	
	COLOR = vec4(backgroundColor, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
