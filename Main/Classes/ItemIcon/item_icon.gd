extends TextureRect

var icon_id : int = -1:
	set(v):
		if not is_node_ready(): await ready
		change_region(v)
		icon_id = v
		
func _ready() -> void:
	texture = texture.duplicate()

func change_region(id: int) -> void:
	if id == -1:
		texture.region = Rect2(32, 32, 0, 0)
	else:
		var x = id % 8
		var y = id / 8
		var rect2 = Rect2(32 * x, 32 * y, 16, 16)
		texture.region = rect2
	size = Vector2(16, 16)
