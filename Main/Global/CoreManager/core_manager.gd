extends Node

const MODEL_CORE = preload("res://Main/Classes/ModelCore/model_core.tscn")

var cores = []

func new_combination(block1: BlockBase, block2: BlockBase) -> void:
	# print("New combination: ", block1, block2)

	if need_new_core(block1, block2):
		var core_instance: ModelCore = MODEL_CORE.instantiate()
		core_instance.core_free.connect(_on_core_free)
		cores.append(core_instance)

		core_instance.global_position = block1.global_position
		get_tree().root.add_child(core_instance)
		core_instance.add_block(block1)
		core_instance.add_block(block2)
	else:
		if block1.core == null:
			block2.core.add_block(block1)
		else:
			block1.core.add_block(block2)
			
func new_core(graph: Dictionary) -> void:
	# print("New Core: ", graph)
	if len(graph) == 1:
		var _block = graph.keys()[0]
		_block.reparent(get_tree().root, true)
		_block.transition_state(BlockBase.State.SINGLE)
		return
			
	var core_instance: ModelCore = MODEL_CORE.instantiate()
	core_instance.core_free.connect(_on_core_free)
	cores.append(core_instance)
	
	core_instance.global_position = graph.keys()[0].global_position
	get_tree().root.add_child(core_instance)
	
	for node in graph.keys():
		core_instance.add_block(node)
		
	


func need_new_core(block1: BlockBase, block2: BlockBase) -> bool:
	if block1.core == null and block2.core == null:
		return true
	return false
	
func _on_core_free(core: ModelCore) -> void:
	cores.erase(core)
