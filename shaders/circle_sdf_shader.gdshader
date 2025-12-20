shader_type canvas_item;
render_mode unshaded;

uniform vec2 virtual_resolution = vec2(512.0, 512.0);

//uniform vec2 mat2_col_0;
//uniform vec2 mat2_col_1;

//uniform float total_elapsed_time;
//uniform vec3 lightPosition;

vec3 roatateVec3_around_y_axis(vec3 vecToRotate, float rotationAmount_rad)
{
	vec3 rotMat_col0 = vec3(cos(rotationAmount_rad), 0.0, -sin(rotationAmount_rad));
	vec3 rotMat_col1 = vec3(0.0, 1.0, 0.0);
	vec3 rotMat_col2 = vec3(-sin(rotationAmount_rad), 0.0, cos(rotationAmount_rad));

	rotMat_col0 = rotMat_col0 * vecToRotate.x;
	rotMat_col1 = rotMat_col1 * vecToRotate.y;
	rotMat_col2 = rotMat_col2 * vecToRotate.z;

	vec3 rotatedVec = rotMat_col0 + rotMat_col1 + rotMat_col2;

	return rotatedVec;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	vec3 spotLightPos = vec3(2.0, 2.0, 0.0);

	spotLightPos = roatateVec3_around_y_axis(spotLightPos, TIME);

	//spotLightPos = LightPos

	vec4 hitCOLOR = vec4(1.0, 0.0, 0.0, 1.0);
	vec4 missCOLOR = vec4(1.0, 1.0, 1.0, 1.0);

	float x_res = virtual_resolution.x;
	float y_res = virtual_resolution.y;

	vec2 NDC_coord = UV * 2.0 - 1.0;
	//I need to flip these or the coordinates don't seem to match up. Maybe a quirk of godot
	// or I am misunderstanding something.
	//NDC_coord.y = -NDC_coord.y;
	NDC_coord.x = -NDC_coord.x;

	vec3 D = normalize(vec3(NDC_coord.x, NDC_coord.y, -1.0));
	vec3 O = vec3(0.0, 0.0, -3.0);
	vec3 C = vec3(0.0, 0.0, 0.0);
	vec3 L = O - C;

	vec3 Ray = vec3(0.0, 0.0, 0.0);

	float r = 1.0;

	float a = dot(D, D);
	float b = 2.0 * dot(L, D);
	float c = dot(L, L) - (r * r);

	float discriminant = pow(b, 2.0) - 4.0 * a * c;

	//if discriminant is >= 0 hitmask = 1.0 else hitmask = 0.0
	float hitMask = float(discriminant >= 0.0);

	if(discriminant >= 0.0) // or if(hitMask == 1.0)
	{
		//Circle collision:
		float discSquared = sqrt(discriminant);

		// Plus before discriminant
		float t_1 = (-b + discSquared) / (2.0 * a);

		// Minus before discriminant
		float t_2 = (-b - discSquared) / (2.0 * a);

		float smaller_t = min(t_1, t_2);

		Ray = O + D * smaller_t;

		vec3 incommingLightRay = normalize(spotLightPos - Ray);
		vec3 surfaceNormal = normalize(Ray - C);

		float specularIntensity = max(dot(incommingLightRay, surfaceNormal), 0.0);

		hitCOLOR = hitCOLOR * specularIntensity;
	}

	vec4 finalColor = mix(missCOLOR, hitCOLOR, hitMask);
	COLOR = vec4(finalColor.r, finalColor.g, finalColor.b, 1.0);
	//COLOR = vec4(0.5, 0.5, 0.0, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
