extends Control

const ITEM_ICON = preload("res://Main/Classes/ItemIcon/item_icon.tscn")

@onready var status_screen: Control = $"../StatusScreen"
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var texture_rect_items_panel: TextureRect = $VBoxContainer/Control_Down/TextureRect_ItemsPanel
@onready var texture_rect_high_light: TextureRect = $VBoxContainer/Control_Down/TextureRect_ItemsPanel/TextureRect_HighLight

@onready var button_delete_block: Button = $HBoxContainer/Control_Left/ButtonDeleteBlock


var blocks = {
	0: preload("res://Main/Scenes/Blocks/Structures/LightArmor/light_armor.tscn"),
	1: preload("res://Main/Scenes/Blocks/Structures/HeavyArmor/heavy_armor.tscn")
}

enum State {
	PLACEMENT,
	DESTRUCTION,
}

var state: State = State.PLACEMENT

var activate: bool = false

#----------------------------------------放置模式参数----------------------------------------
var items = []
var prep_blocks = []

var block_combining: bool = false
var block_rotation = 0.0

var item_index: int = 0:
	set(v):
		if not is_node_ready(): await ready
		change_high_light(v)
		if items[v].icon_id == -1:
			clear_last_prep_block()
		else:
			clear_last_prep_block()
			add_prep_block(v)
		item_index = v
		
func _ready() -> void:
	for i in range(6):
		var item_instance = ITEM_ICON.instantiate()
		item_instance.icon_id = -1
		item_instance.position = Vector2(i * 23 + 6, 12)
		texture_rect_items_panel.add_child(item_instance)
		items.append(item_instance)
		
	add_item(0, 0)
	add_item(1, 1)
	item_index = 0
	
	hide_prep_blocks()
		
func _process(_delta: float) -> void:
	match state:
		State.PLACEMENT:
			var rotation_acceleration = Input.get_axis("Q", "E")
			block_rotation += rotation_acceleration * _delta * 2.5
			block_follow_cursor()

		State.DESTRUCTION:
			pass


func _unhandled_input(event: InputEvent) -> void:
	if not activate:
		return

	match state:
		State.PLACEMENT:
			_on_unhandled_input_placement(event)

		State.DESTRUCTION:
			_on_unhandled_input_destruction(event)

	if event.is_action_pressed("Esc"):
		if state == State.PLACEMENT:
			leave_screen()
		else:
			transition_state(state, State.PLACEMENT)

			

func _on_unhandled_input_placement(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			item_index = clampi(item_index + 1, 0, 5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			item_index = clampi(item_index - 1, 0, 5)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_instance_valid(prep_blocks[-1]) or len(prep_blocks) == 0 or block_combining:
				print("当前没有方块或当前方块并没有合并完成")
				return
			prep_blocks[-1].transition_state(BlockBase.State.WAIT)
			block_combining = true
			prep_blocks[-1].block_combine_finished.connect(_on_block_combine_finished)
			prep_blocks.erase(prep_blocks[-1])
			add_prep_block(item_index)
		
	if event.is_action_pressed("1"):
		item_index = 0
	elif event.is_action_pressed("2"):
		item_index = 1
	elif event.is_action_pressed("3"):
		item_index = 2
	elif event.is_action_pressed("4"):
		item_index = 3
	elif event.is_action_pressed("5"):
		item_index = 4
	elif event.is_action_pressed("6"):
		item_index = 5

func _on_unhandled_input_destruction(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var selected_block = GlobalVars.selected_block
			if selected_block == null:
				print("没有选择删除的方块")
				return
			if selected_block.core == null:
				selected_block.queue_free()
			else:
				selected_block.core.delete_block(selected_block)

func add_item(index: int, id: int) -> void:
	items[index].icon_id = id
	
func remove_item(index: int) -> void:
	items[index].icon_id = -1

func block_follow_cursor() -> void:
	var mouse_position = get_global_mouse_position()

	if len(prep_blocks) > 0 and is_instance_valid(prep_blocks[-1]) and prep_blocks[-1].state == BlockBase.State.ON_CURSOR:
		prep_blocks[-1].global_position = mouse_position
		prep_blocks[-1].rotation = block_rotation

func add_prep_block(index: int) -> void:
	var instance = blocks[items[index].icon_id].instantiate()
	instance.transition_state(BlockBase.State.ON_CURSOR)
	get_tree().root.add_child.call_deferred(instance)
	prep_blocks.append(instance)
	
func clear_last_prep_block() -> void:
	if len(prep_blocks) > 0 and is_instance_valid(prep_blocks[-1]):
		prep_blocks[-1].queue_free()
	for block in prep_blocks:
		if not is_instance_valid(block):
			prep_blocks.erase(block)

func hide_prep_blocks() -> void:
	for block in prep_blocks:
		if not is_instance_valid(block):
			continue
		block.transition_state(BlockBase.State.PREP)
		
func show_prep_blocks() -> void:
	for block in prep_blocks:
		if not is_instance_valid(block):
			continue
		block.transition_state(BlockBase.State.ON_CURSOR)

func transition_state(from: State, to: State) -> void:
	match from:
		State.PLACEMENT:
			hide_prep_blocks()
		State.DESTRUCTION:
			GlobalVars.can_delete_block = false

	match to:
		State.PLACEMENT:
			show_prep_blocks()
		State.DESTRUCTION:
			GlobalVars.can_delete_block = true

	state = to

func enter_screen() -> void:
	activate = true

	animation_player.play("show_screen")
	set_process(true)

	state = State.PLACEMENT
	
func leave_screen() -> void:
	activate = false

	animation_player.play("hide_screen")
	set_process(false)
	status_screen.show_screen()
	
func change_high_light(index: int) -> void:
	texture_rect_high_light.position = Vector2(index * 23, 4)

func _on_button_edit_pressed() -> void:
	enter_screen()

func _on_button_delete_block_pressed() -> void:
	transition_state(state, State.DESTRUCTION)
	

func _on_block_combine_finished() -> void:
	block_combining = false
