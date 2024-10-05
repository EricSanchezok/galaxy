shader_type canvas_item;

uniform vec2 circle_center = vec2(0.5);
uniform float circle_radius = 16;

void fragment() {
    float dist = distance(circle_center, vec2(mix(circle_center.x, UV.x, 1.0), UV.y));
	
	float uv_radius = circle_radius / 360.0;
	
	vec4 current_color = COLOR;
	
	if (dist > uv_radius){
	    COLOR = vec4(current_color.rgb, 0.0);
	}
	else{
		COLOR = current_color;
	}
		

}
