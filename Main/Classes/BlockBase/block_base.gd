class_name BlockBase
extends RigidBody2D

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

func _ready() -> void:
	freeze_mode = FreezeMode.FREEZE_MODE_STATIC
	
func _process(_delta: float) -> void:
	if state == State.ON_CURSOR:
		if len(blocks_nearby) == 0:
			marker_combination = [null, null]
			line_2d_combine.points[0] = Vector2.ZERO
			line_2d_combine.points[1] = Vector2.ZERO
			return
		for block in blocks_nearby:
			var min_distance = INF
			for my_combine_marker in combining_markers.get_children():
				for combine_marker in block.combining_markers.get_children():
					var dis_squar = my_combine_marker.global_position.distance_squared_to(combine_marker.global_position)
					if dis_squar <= min_distance:
						min_distance = dis_squar
						marker_combination[0] = my_combine_marker
						marker_combination[1] = combine_marker

		line_2d_combine.points[0] = marker_combination[0].position
		line_2d_combine.points[1] = to_local(marker_combination[1].global_position)
		
	elif state == State.WAIT:
		line_2d_combine.visible = false
		if marker_combination[0] == null or marker_combination[1] == null:
			transition_state(State.SINGLE)
		else:
			print("!")
	
func transition_state(to: State) -> void:
	if not is_node_ready(): await ready
	
	state = to
	
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

func _on_area_2d_drag_area_entered(area: Area2D) -> void:
	blocks_nearby.append(area.owner)

func _on_area_2d_drag_area_exited(area: Area2D) -> void:
	blocks_nearby.erase(area.owner)
