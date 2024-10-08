shader_type canvas_item;

uniform bool is_hover;

void fragment() {
	vec4 current_color = COLOR;

	if (is_hover){
	    COLOR = current_color * 1.5;
	}
	else{
		COLOR = current_color;
	}


}
