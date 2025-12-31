shader_type canvas_item;

uniform sampler2D CL_2_Tex: filter_nearest, repeat_disable;

const float C0_RAY_INTERVAL = 2.0;
const float CASCADE_LEVEL = 1.0;
const float UPPER_CASCADE_LEVEL = 2.0;
const ivec2 CASCADE_TEXTURE_SIZE_XY = ivec2(1024, 1024); // 1024 by 1024

const int MAX_NO_RAY_MARCH_STEPS = 64;

const float C4_START_DISTANCE = (C0_RAY_INTERVAL * (1.0 - (pow(4.0, CASCADE_LEVEL + 3.0)))) / (1.0 - 4.0);  // We use 4 because the origin moves 4x further away as we increase the cascade index from 0
const float C3_START_DISTANCE = (C0_RAY_INTERVAL * (1.0 - (pow(4.0, CASCADE_LEVEL + 2.0)))) / (1.0 - 4.0);  // We use 4 because the origin moves 4x further away as we increase the cascade index from 0
const float C2_START_DISTANCE = (C0_RAY_INTERVAL * (1.0 - (pow(4.0, CASCADE_LEVEL + 1.0)))) / (1.0 - 4.0);
const float C1_START_DISTANCE = (C0_RAY_INTERVAL * (1.0 - (pow(4.0, CASCADE_LEVEL)))) / (1.0 - 4.0);
const float MAX_RAY_LENGTH = C0_RAY_INTERVAL * (pow(4.0, CASCADE_LEVEL)); // we do 4 ^ Cascade level == 4 ^ 4 since we are on cascade level 4

const float RAY_MARCH_HIT_THRESHOLD = 0.6;

uniform vec2 u_C4_probe_offset = vec2(16.0, 16.0);
uniform vec2 u_C4_xy_NO_probes = vec2(32.0, 32.0);
uniform vec2 u_C3_probe_offset = vec2(8.0, 8.0);
uniform vec2 u_C3_xy_NO_probes = vec2(64.0, 64.0);
uniform vec2 u_C2_probe_offset = vec2(4.0, 4.0);
uniform vec2 u_C2_xy_NO_probes = vec2(128.0, 128.0);
uniform vec2 u_C1_probe_offset = vec2(2.0, 2.0);
uniform vec2 u_C1_xy_NO_probes = vec2(256.0, 256.0);

uniform float u_C1_no_rays_per_probe = 16.0;
uniform float u_C2_no_rays_per_probe = 64.0;
uniform float u_C3_no_rays_per_probe = 256.0;
uniform float u_C4_no_rays_per_probe = 1024.0;

uniform sampler2D segmentLocationCoords_tex: filter_nearest, repeat_disable;
uniform sampler2D segmentColors_tex: filter_nearest, repeat_disable;
uniform int arrayLargestIndex;

const int SDF_ARRAY_SIZE = 500;

uniform vec2 currentClickPosition;
uniform vec2 currentMousePosition;
uniform int isMouseHeld;

uniform float segmentThickness;
uniform vec4 currentSelectedColor;

uniform vec2 u_virtual_resolution = vec2(1024, 1024);

//returns texture point value which is a vec4
vec4 read_2D_data_position_from_CL2_Tex(int ix, int iy, ivec2 arraySize2D)
{
	float ux = (float(ix) + 0.5) / float(arraySize2D.x);
	float uy = (float(iy) + 0.5) / float(arraySize2D.y);
	return texture(CL_2_Tex, vec2(ux, 1.0 - uy));
}

vec3 getUpperCascadeCL2RayColor(vec2 probe, ivec2 cellSamplePoint)
{
	int xSamplePos = int(probe.x) * (int(u_virtual_resolution.x) / int(u_C2_xy_NO_probes.x));
	int ySamplePos = int(probe.y) * (int(u_virtual_resolution.x) / int(u_C2_xy_NO_probes.y));
	
	xSamplePos = xSamplePos + cellSamplePoint.x;
	ySamplePos = ySamplePos + cellSamplePoint.y;
	
	vec4 rayColor = read_2D_data_position_from_CL2_Tex(xSamplePos, ySamplePos, CASCADE_TEXTURE_SIZE_XY);
	
	return vec3(rayColor.x, rayColor.y, rayColor.z);
}

vec3 BilinearInterpolateBetweenCL2Probes(vec2 weightValue, vec3 TL_Probe_Color, vec3 TR_Probe_Color, vec3 BL_Probe_Color, vec3 BR_Probe_Color)
{
	// Interpolate horizontally
	vec3 top = mix(TL_Probe_Color, TR_Probe_Color, weightValue.x);
	vec3 bottom = mix(BL_Probe_Color, BR_Probe_Color, weightValue.x);
	
	// Interpolate vertically
	return mix(top, bottom, weightValue.y);
}

vec3 getUpperCascadeColorToMerge(vec2 TL_Probe, float ray_angle_radians, float currentCascadeRaysPerProbe, float upperCascadeRaysPerProbe, vec2 currentProbeXYBilinearWeights)
{
	//Find what section of the CL2 texture you need to sample. 
	float upperCascadeAngleSegment = ((2.0*PI) / upperCascadeRaysPerProbe);
	float currentCascade_angle_segment = ((2.0*PI) / currentCascadeRaysPerProbe);
	float currentAngle = ray_angle_radians - (currentCascade_angle_segment * 0.5);
	float NoOfUpperCascadeAngleSegmentsInCurrentAngle = currentAngle / upperCascadeAngleSegment;
	float angleZoneInUpperCascade = (NoOfUpperCascadeAngleSegmentsInCurrentAngle / 4.0) - 1.0;
	
	float cellSamplePoint_y_float = angleZoneInUpperCascade / (sqrt(upperCascadeRaysPerProbe) / 4.0);
	int cellSamplePoint_y = int(cellSamplePoint_y_float);
	int cellSamplePoint_x = 0;
	
	if(int(angleZoneInUpperCascade) != 0)
	{
		cellSamplePoint_x = int((angleZoneInUpperCascade) * 4.0) % int((sqrt(upperCascadeRaysPerProbe) / 4.0));
		
	}
	
	// for safety. clamp the cell sample points to ensure they are in the desired range:
	cellSamplePoint_x = clamp(cellSamplePoint_x, 0, ((int(u_virtual_resolution.x) / int(u_C2_xy_NO_probes.x)) - 4)); // - 4 because we do "cellSamplePoint_x + 3" later and if we are on 7 somehow and each cell is only 8 long, we will bleed into the neighbor cell
	cellSamplePoint_y = clamp(cellSamplePoint_y, 0, ((int(u_virtual_resolution.y) / int(u_C2_xy_NO_probes.y)) - 1));
	
	// Get probes for bilinear interpolation
	//Probes have been clamped pre function call so don't worry about calling outside of bounds (e.g. probe 33)
	vec2 TR_Probe = vec2(TL_Probe.x + 1.0, TL_Probe.y);
	vec2 BL_Probe = vec2(TL_Probe.x, TL_Probe.y + 1.0);
	vec2 BR_Probe = vec2(TL_Probe.x + 1.0, TL_Probe.y + 1.0);
	
	// Get 4 rays corresponding to this ray and average the values together for each probe
	
	// TL Probe 4 relevant rays average color:
	vec3 TL_Probe_Color = getUpperCascadeCL2RayColor(TL_Probe, ivec2(cellSamplePoint_x, cellSamplePoint_y));
	TL_Probe_Color = TL_Probe_Color + getUpperCascadeCL2RayColor(TL_Probe, ivec2(cellSamplePoint_x + 1, cellSamplePoint_y));
	TL_Probe_Color = TL_Probe_Color + getUpperCascadeCL2RayColor(TL_Probe, ivec2(cellSamplePoint_x + 2, cellSamplePoint_y));
	TL_Probe_Color = TL_Probe_Color + getUpperCascadeCL2RayColor(TL_Probe, ivec2(cellSamplePoint_x + 3, cellSamplePoint_y));
	
	// Divide by 4 to average the color values
	TL_Probe_Color = TL_Probe_Color / 4.0;
	
	// TR Probe 4 relevant rays average color:
	vec3 TR_Probe_Color = getUpperCascadeCL2RayColor(TR_Probe, ivec2(cellSamplePoint_x, cellSamplePoint_y));
	TR_Probe_Color = TR_Probe_Color + getUpperCascadeCL2RayColor(TR_Probe, ivec2(cellSamplePoint_x + 1, cellSamplePoint_y));
	TR_Probe_Color = TR_Probe_Color + getUpperCascadeCL2RayColor(TR_Probe, ivec2(cellSamplePoint_x + 2, cellSamplePoint_y));
	TR_Probe_Color = TR_Probe_Color + getUpperCascadeCL2RayColor(TR_Probe, ivec2(cellSamplePoint_x + 3, cellSamplePoint_y));
	
	TR_Probe_Color = TR_Probe_Color / 4.0;
	
	// BL Probe 4 relevant rays average color:
	vec3 BL_Probe_Color = getUpperCascadeCL2RayColor(BL_Probe, ivec2(cellSamplePoint_x, cellSamplePoint_y));
	BL_Probe_Color = BL_Probe_Color + getUpperCascadeCL2RayColor(BL_Probe, ivec2(cellSamplePoint_x + 1, cellSamplePoint_y));
	BL_Probe_Color = BL_Probe_Color + getUpperCascadeCL2RayColor(BL_Probe, ivec2(cellSamplePoint_x + 2, cellSamplePoint_y));
	BL_Probe_Color = BL_Probe_Color + getUpperCascadeCL2RayColor(BL_Probe, ivec2(cellSamplePoint_x + 3, cellSamplePoint_y));
	
	BL_Probe_Color = BL_Probe_Color / 4.0;
	
	// BR Probe 4 relevant rays average color:
	vec3 BR_Probe_Color = getUpperCascadeCL2RayColor(BR_Probe, ivec2(cellSamplePoint_x, cellSamplePoint_y));
	BR_Probe_Color = BR_Probe_Color + getUpperCascadeCL2RayColor(BR_Probe, ivec2(cellSamplePoint_x + 1, cellSamplePoint_y));
	BR_Probe_Color = BR_Probe_Color + getUpperCascadeCL2RayColor(BR_Probe, ivec2(cellSamplePoint_x + 2, cellSamplePoint_y));
	BR_Probe_Color = BR_Probe_Color + getUpperCascadeCL2RayColor(BR_Probe, ivec2(cellSamplePoint_x + 3, cellSamplePoint_y));
	
	BR_Probe_Color = BR_Probe_Color / 4.0;
	
	vec3 FinalColor = BilinearInterpolateBetweenCL2Probes(currentProbeXYBilinearWeights, TL_Probe_Color, TR_Probe_Color, BL_Probe_Color, BR_Probe_Color);
	
	return FinalColor;
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
	
	// -- SAFETY CHECK --
	//float denom = dot(ba, ba);
	//if (denom < 1e-6) 
	//{
		//return length(pa);
	//}
	
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h );
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

// -------------------------------------------------------------

void vertex() 
{
	// Called for every vertex the material is visible on.
}

void fragment()
{
	
	// SubViewport textures are GPU render targets. GPU APIs (OpenGL / Vulkan) define:
	// therefore:   Texture origin = bottom-left.
	//
	// So we need to flip the UV's y value to sample correctly.
	vec2 corrected_uv_forUpperCascadeSampling = vec2(UV.x, 1.0 - UV.y);
	
	vec2 spacing_between_probes = u_virtual_resolution / u_C1_xy_NO_probes;
	
	
	// 1. For this cascade level, find the current ray's emitting probe position
	vec2 texel_position = floor(UV * u_virtual_resolution);
	vec2 current_probe = floor(texel_position / spacing_between_probes);
	vec2 current_probe_pos = (current_probe * spacing_between_probes) + u_C1_probe_offset;
	
	// 2. Find ray direction from the probe
	vec2 local_grid_pos = mod(texel_position, spacing_between_probes);
	float ray_angle_radians = local_grid_pos.y * ((2.0 * PI) / spacing_between_probes.x) + local_grid_pos.x * ((2.0 * PI) / u_C1_no_rays_per_probe) + ((2.0 * PI) / (u_C1_no_rays_per_probe * 2.0));
	
	vec2 ray_dir_normalized = vec2(1.0, 0.0);
	ray_dir_normalized = rotate_anticlockwise(ray_dir_normalized, ray_angle_radians);
	
	// 3. Find ray starting position
	vec2 ray_start_pos = current_probe_pos + (ray_dir_normalized * C1_START_DISTANCE);
	float march_distance = MAX_RAY_LENGTH;
	
	float ray_distance_from_probe = length(ray_start_pos - current_probe_pos);
	
	vec2 current_ray_pos = ray_start_pos;
	
	bool ray_march_hit_bool = false;
	int hit_index = -1;
	
	int current_ray_march_step = 0;
	
	while(current_ray_march_step < MAX_NO_RAY_MARCH_STEPS)
	{
		current_ray_march_step = current_ray_march_step + 1;
		
		march_distance = MAX_RAY_LENGTH;
		
		if(ray_distance_from_probe > MAX_RAY_LENGTH)
		{
			break;
		}
		
		for(int i = 0; i < SDF_ARRAY_SIZE; i++)
		{
			if(i > arrayLargestIndex)
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
	
	if(hit_index >= 0) //occulude the higher cascade color
	{
		//Store the color data in the C1 texture
		vec4 v_color = read_data_color(hit_index);
		COLOR = vec4(v_color.r, v_color.g, v_color.b, 1.0);
		//COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	}
	else //merge with the higher cascade color
	{
		//Handle the edge case where a ray is located below the offset (16 in the case of cascade 4) and is not surrounded by 4 probes
		//	in this case, simply use the nearest probe. 
		
		// This assumed x and y are the same
		float C2probeSpaceing = u_virtual_resolution.x / u_C2_xy_NO_probes.x; 
		float max_center = u_C2_probe_offset.x + float(u_C2_xy_NO_probes.x - 1.0) * C2probeSpaceing; 
		
		vec2 point_clamped = clamp(current_probe_pos, u_C2_probe_offset, vec2(max_center, max_center));
		
		vec2 P_C2_CO = point_clamped - u_C2_probe_offset;
		vec2 positionalValue = P_C2_CO / C2probeSpaceing;
		vec2 TL_Probe = floor(positionalValue);
		
		//ensure it is withing the range 0 to 30, so we do not get any out of bounds behaviour:
		TL_Probe = clamp(TL_Probe, vec2(0.0, 0.0), u_C2_xy_NO_probes - 2.0); // 0 - 30
		
		// we can use the positionalValue to find the weight that will be used for bilinear interpolation.
		vec2 current_probe_x_y_bilinear_weights = positionalValue - vec2(TL_Probe); // this is pretty much like doing fract to get everything after the dot of positionalValue
		
		vec3 FinalColor = getUpperCascadeColorToMerge(TL_Probe, ray_angle_radians, u_C1_no_rays_per_probe, u_C2_no_rays_per_probe, current_probe_x_y_bilinear_weights);
		
		COLOR = vec4(FinalColor.x, FinalColor.y, FinalColor.z, 1.0); //black default
		//COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	}
}


//
//void fragment() 
//{
	//// SubViewport textures are GPU render targets. GPU APIs (OpenGL / Vulkan) define:
	//// therefore:   Texture origin = bottom-left.
	////
	//// So we need to flip the UV's y value to sample correctly.
	//vec2 corrected_uv = vec2(UV.x, 1.0 - UV.y);
	//COLOR = texture(CL_4_Tex, corrected_uv);
	////COLOR = vec4(0.5, 0.5, 0.0, 1.0);
//}

