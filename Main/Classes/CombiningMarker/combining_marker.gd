class_name CombiningMarker
extends Marker2D

@onready var label_lock: Label = $Label_Lock

enum MarkerDir{
	UP,
	DOWN,
	LEFT,
	RIGHT
}

@export var marker_dir: MarkerDir
var lock: bool = false:
	set(v):
		if not is_node_ready(): await ready
		lock = v
		if lock:
			label_lock.text = "T"
		else:
			label_lock.text = "F"


func _process(_delta: float) -> void:
	label_lock.rotation = -global_rotation
