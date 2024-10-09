class_name BlockBase
extends RigidBody2D

@onready var sprite_2d_icon: Sprite2D = $Sprite2D_Icon

@onready var collision_shape_2d_phy: CollisionShape2D = $CollisionShape2D_Phy
@onready var area_2d_drag: Area2D = $Area2D_Drag
@onready var line_2d_combine: Line2D = $Line2D_Combine
@onready var combining_markers: Node2D = $CombiningMarkers

@export var id: int = 0
@export var max_durability : int = 10
var durability : int = max_durability:
	set(v):
		durability = clampi(v, 0, max_durability)
		
enum State{
	PREP,
	ON_CURSOR,
	WAIT,
	SINGLE,
	WITH_CORE,
}

var state: State = State.ON_CURSOR

var blocks_nearby = []
var marker_combination = [null, null]
var target_block: BlockBase = null

var core: ModelCore = null
var max_lengh: int = 1

signal block_combine_finished
var rotation_speed = 15
var move_speed = 100
var rotation_threshold = 0.1  # 设置旋转的阈值
var position_threshold = 0.1  # 设置位置的阈值

var tween_scale: Tween

func _ready() -> void:
	freeze_mode = FreezeMode.FREEZE_MODE_STATIC
	
func _process(_delta: float) -> void:
	if state == State.ON_CURSOR:
		if len(blocks_nearby) == 0:
			marker_combination = [null, null]
			line_2d_combine.points[0] = Vector2.ZERO
			line_2d_combine.points[1] = Vector2.ZERO
			target_block = null
			return

		var min_distance = INF
		for block in blocks_nearby:
			for my_combine_marker in combining_markers.get_children():
				if my_combine_marker.lock:
					continue
				for combine_marker in block.combining_markers.get_children():
					if combine_marker.lock:
						continue
					var dis_squar = my_combine_marker.global_position.distance_squared_to(combine_marker.global_position)
					if dis_squar <= min_distance:
						min_distance = dis_squar
						marker_combination[0] = my_combine_marker
						marker_combination[1] = combine_marker
						target_block = block

		line_2d_combine.points[0] = marker_combination[0].position
		line_2d_combine.points[1] = to_local(marker_combination[1].global_position)
		
	elif state == State.WAIT:
		line_2d_combine.visible = false
		if marker_combination[0] == null or marker_combination[1] == null or target_block == null:
			transition_state(State.SINGLE)
			block_combine_finished.emit()
		else:
			var my_marker_direction = markerdir2Vector2(marker_combination[0].marker_dir, -marker_combination[0].global_rotation)
			var marker_direction = markerdir2Vector2(marker_combination[1].marker_dir, -marker_combination[1].global_rotation)

			var rotation_diff = my_marker_direction.angle_to(-marker_direction)
			if abs(rotation_diff) < rotation_threshold:
				rotation = rotation - rotation_diff  # 直接设置为目标值
			else:
				rotation = lerpf(rotation, rotation - rotation_diff, rotation_speed * _delta)

			var position_dir = marker_combination[1].global_position - marker_combination[0].global_position
			var position_diff = position_dir.length()
			if position_diff < position_threshold:
				position = position + position_dir  # 直接设置为目标值
			else:
				position = position.move_toward(position + position_dir, move_speed * _delta)

			if rotation_diff < rotation_threshold and position_diff < position_threshold:
				CoreManager.new_combination(target_block, self)


func markerdir2Vector2(dir: CombiningMarker.MarkerDir, _rotation: float) -> Vector2:
	match dir:
		CombiningMarker.MarkerDir.UP:
			return Vector2(0, 1).rotated(_rotation)
		CombiningMarker.MarkerDir.DOWN:
			return Vector2(0, -1).rotated(_rotation)
		CombiningMarker.MarkerDir.LEFT:
			return Vector2(-1, 0).rotated(_rotation)
		CombiningMarker.MarkerDir.RIGHT:
			return Vector2(1, 0).rotated(_rotation)
	return Vector2.ZERO
	
func transition_state(to: State) -> void:
	if not is_node_ready(): await ready
	
	match to:
		State.PREP:
			collision_shape_2d_phy.disabled = true
			area_2d_drag.monitoring = false
			area_2d_drag.monitorable = false
			freeze = true
			visible = false
			
			set_process(false)
			set_physics_process(false)
			
		State.ON_CURSOR:
			collision_shape_2d_phy.disabled = true
			area_2d_drag.monitoring = true
			area_2d_drag.monitorable = false
			
			freeze = true
			visible = true
			
			set_process(true)
			set_physics_process(false)
			
		State.WAIT:
			collision_shape_2d_phy.disabled = true
			area_2d_drag.monitoring = false
			area_2d_drag.monitorable = false
			
			freeze = true
			visible = true
			
			set_process(true)
			set_physics_process(false)
			
		State.SINGLE:
			collision_shape_2d_phy.disabled = false
			area_2d_drag.monitoring = false
			area_2d_drag.monitorable = true
			freeze = false
			visible = true
			
			set_process(false)
			set_physics_process(true)
			
		State.WITH_CORE:
			collision_shape_2d_phy.disabled = true
			area_2d_drag.monitoring = false
			area_2d_drag.monitorable = true
			freeze = true
			visible = true
			
			set_process(false)
			set_physics_process(false)

	state = to
	
func animate_scale(is_reduce: bool) -> void:
	if tween_scale and tween_scale.is_running():
		tween_scale.kill()
	
	tween_scale = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	if is_reduce:
		tween_scale.tween_property(sprite_2d_icon, "scale", Vector2(0.8, 0.8), 0.2)
	else:
		tween_scale.tween_property(sprite_2d_icon, "scale", Vector2(1.0, 1.0), 0.2)

func _on_area_2d_drag_area_entered(area: Area2D) -> void:
	blocks_nearby.append(area.owner)

func _on_area_2d_drag_area_exited(area: Area2D) -> void:
	blocks_nearby.erase(area.owner)

func _on_area_2d_mouse_mouse_entered() -> void:
	if not GlobalVars.can_delete_block:
		return
	animate_scale(true)
	GlobalVars.selected_block = self

func _on_area_2d_mouse_mouse_exited() -> void:
	if not GlobalVars.can_delete_block:
		return
	animate_scale(false)
	GlobalVars.selected_block = null
