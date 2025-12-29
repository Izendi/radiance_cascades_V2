shader_type canvas_item;

uniform sampler2D segmentLocationCoords_tex;
uniform sampler2D segmentColors_tex;
uniform int arrayLargestIndex;

const int SDF_ARRAY_SIZE = 500;

uniform vec2 currentClickPosition;
uniform vec2 currentMousePosition;
uniform int isMouseHeld;

uniform float segmentThickness;
uniform vec4 currentSelectedColor;

uniform vec2 u_virtual_resolution = vec2(1024, 1024);

//uniform float total_elapsed_time;

vec4 read_2D_data_position(int ix, int iy, ivec2 arraySize2D)
{
	float ux = (float(ix) + 0.5) / float(arraySize2D.x);
	float uy = (float(iy) + 0.5) / float(arraySize2D.y); 
	return texture(segmentLocationCoords_tex, vec2(ux, uy)); //this needs to be changed to the higher cascade level
}

vec4 read_data_position(int i)
{
	float u = (float(i) + 0.5) / float(SDF_ARRAY_SIZE);
	return texture(segmentLocationCoords_tex, vec2(u, 0.5));
}

vec4 read_data_color(int i)
{
	float u = (float(i) + 0.5) / float(SDF_ARRAY_SIZE);
	return texture(segmentColors_tex, vec2(u, 0.5));
}

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

vec2 rotate_anticlockwise(vec2 v, float angle) 
{
	float c = cos(angle);
	float s = sin(angle);
	
	return vec2(
		v.x * c - v.y * s,
		v.x * s + v.y * c
		);
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}


void vertex() {
	// Called for every vertex the material is visible on.
}

const float C0_RAY_INTERVAL = 2.0;
const float CASCADE_LEVEL = 4.0;

const int MAX_NO_RAY_MARCH_STEPS = 64;

const float C4_START_DISTANCE = (C0_RAY_INTERVAL * (1.0 - (pow(4.0, CASCADE_LEVEL)))) / (1.0 - 4.0);  // We use 4 because the origin moves 4x further away as we increase the cascade index from 0
const float MAX_RAY_LENGTH = C0_RAY_INTERVAL * (pow(4.0, CASCADE_LEVEL)); // we do 4 ^ Cascade level == 4 ^ 4 since we are on cascade level 4

const float RAY_MARCH_HIT_THRESHOLD = 0.6;

uniform vec2 u_C4_probe_offset = vec2(16.0, 16.0);
uniform vec2 u_C4_xy_NO_probes = vec2(32.0, 32.0);
uniform float u_no_rays_per_probe = 1024.0;


void fragment()
{
	
	vec2 spacing_between_probes = u_virtual_resolution / u_C4_xy_NO_probes;
	
	
	// 1. For this cascade level, find the current ray's emitting probe position
	vec2 texel_position = floor(UV * u_virtual_resolution);
	vec2 current_probe = floor(texel_position / spacing_between_probes);
	vec2 current_probe_pos = (current_probe * spacing_between_probes) + u_C4_probe_offset;
	
	// 2. Find ray direction from the probe
	vec2 local_grid_pos = mod(texel_position, spacing_between_probes);
	float ray_angle_radians = local_grid_pos.y * ((2.0 * PI) / spacing_between_probes.x) + local_grid_pos.x * ((2.0 * PI) / u_no_rays_per_probe) + ((2.0 * PI) / (u_no_rays_per_probe * 2.0));
	
	vec2 ray_dir_normalized = vec2(1.0, 0.0);
	ray_dir_normalized = rotate_anticlockwise(ray_dir_normalized, ray_angle_radians);
	
	// 3. Find ray starting position
	float C4_length = C4_START_DISTANCE;
	vec2 ray_start_pos = current_probe_pos + (ray_dir_normalized * C4_START_DISTANCE);
	float march_distance = C4_length;
	
	float ray_distance_from_probe = length(ray_start_pos - current_probe_pos);
	
	vec2 current_ray_pos = ray_start_pos;
	
	bool ray_march_hit_bool = false;
	int hit_index = -1;
	
	int current_ray_march_step = 0;
	
	while(current_ray_march_step < MAX_NO_RAY_MARCH_STEPS)
	{
		current_ray_march_step = current_ray_march_step + 1;
		
		if(ray_distance_from_probe > MAX_RAY_LENGTH)
		{
			break;
		}
		
		for(int i = 0; i < SDF_ARRAY_SIZE; i++)
		{
			if(i >= arrayLargestIndex)
			{
				break;
			}
			
			vec4 v_location = read_data_position(i);
			vec4 v_color = read_data_color(i);
			
			vec2 clickPos = vec2(v_location.x, v_location.y);
			vec2 releasePos = vec2(v_location.z, v_location.w);
			
			// scale click and release position to 1024 by 1024 resolution, since segment drawing screen is 512 by 512:
			clickPos = clickPos * 2.0;
			releasePos = releasePos * 2.0;
			
			//Check if rays current position hits a segment
			float currentPositionDistanceFromSegment = (sdSegment(current_ray_pos, clickPos, releasePos) - v_color.w);
			if(currentPositionDistanceFromSegment < RAY_MARCH_HIT_THRESHOLD)
			{
				//HIT
				hit_index = i;
				break;
			}
			else
			{
				if(currentPositionDistanceFromSegment < march_distance)
				{
					//This will store the shortest march distance
					march_distance = currentPositionDistanceFromSegment;
				}
			}
			
		}
		
		if(hit_index >= 0)
		{
			break;
		}
		
		//March the shortest march distance found by checking the distances between this ray and all sdfs
		current_ray_pos = current_ray_pos + (ray_dir_normalized * march_distance);
		
		ray_distance_from_probe = length(current_ray_pos - current_probe_pos);
		
	}
	
	if(hit_index >= 0)
	{
		//Store the color data in the C4 texture
		vec4 v_color = read_data_color(hit_index);
		COLOR = vec4(v_color.r, v_color.g, v_color.b, 1.0);
	}
	else
	{
		COLOR = vec4(0.0, 0.0, 1.0, 1.0); //black default
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
