shader_type canvas_item;

uniform sampler2D input_tex;
uniform vec2 mousePos;
uniform int mouseClick;

uniform vec2 viewport_size;

float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment()
{
	vec2 frag_pixel = UV * viewport_size;

	float x_res = 1.0 / SCREEN_PIXEL_SIZE.x;
	float y_res = 1.0 / SCREEN_PIXEL_SIZE.y;

	vec2 resolution = vec2(x_res, y_res);

	vec2 mousePos_uv = mousePos / resolution;

	// Not sure why, but if I don't flip the UV.y i get weird mirroing aroung the x axis. !!!
	vec2 newUV = vec2(UV.x, 1.0 - UV.y);
	COLOR = texture(input_tex, newUV);



	if(mouseClick == 1)
	{
		//COLOR = vec4(mousePos_uv.x, mousePos_uv.y, 0.0, 1.0);
		//vec2 frag_pixel = UV * resolution;

		float dist = distance(frag_pixel, mousePos);

		//if (dist < 0.5)
		//{
			//COLOR = vec4(1.0, 0.0, 0.0, 1.0);
		//}

		if(floor(frag_pixel + 0.5) == floor(mousePos + 0.5))
		{
			COLOR = vec4(0.0, 1.0, 0.0, 1.0);
		}

		//if(sdCircle((frag_pixel - mousePos), 1.0) <= 0.0)
		//{
			//COLOR = vec4(1.0, 0.0, 0.0, 1.0);
		//}

	}


}
