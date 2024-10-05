extends TextureRect

func _process(_delta: float) -> void:
	var mouse_position = get_global_mouse_position()
	var x_diff = mouse_position.x - global_position.x
	var y_diff = mouse_position.y - global_position.y
	
	var center_pos = Vector2(x_diff / size.x, y_diff / size.y)
	material.set_shader_parameter("circle_center", center_pos)
	
	var direction = Vector2(0, 0)
	
	if x_diff >= size.x/2 + 64:
		direction += Vector2(1, 0)
	elif x_diff <= size.x/2 - 64:
		direction += Vector2(-1, 0)
		
	if y_diff >= size.y/2 + 64:
		direction += Vector2(0, 1)
	elif y_diff <= size.y/2 - 64:
		direction += Vector2(0, -1)
		
	global_position += direction * 64
		
