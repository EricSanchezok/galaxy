extends Button

@onready var texture_rect_icon: TextureRect = $TextureRect_Icon

var tween_color: Tween
var tween_scale: Tween

func animate_scale(is_reduce: bool) -> void:
	if tween_scale and tween_scale.is_running():
		tween_scale.kill()
	
	tween_scale = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	if is_reduce:
		tween_scale.tween_property(self, "scale", Vector2(0.8, 0.8), 0.2)
	else:
		tween_scale.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
		
func _on_mouse_entered() -> void:
	texture_rect_icon.material.set_shader_parameter("is_hover", true)
		
func _on_mouse_exited() -> void:
	texture_rect_icon.material.set_shader_parameter("is_hover", false)

func _on_button_down() -> void:
	animate_scale(true)

func _on_button_up() -> void:
	animate_scale(false)
