extends Node

const MODEL_CORE = preload("res://Main/Classes/ModelCore/model_core.tscn")

var cores = []


func new_combination(block1: BlockBase, block2: BlockBase) -> void:
	print("New combination: ", block1, block2)

	if need_new_core(block1, block2):
		var core_instance: ModelCore = MODEL_CORE.instantiate()
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


func need_new_core(block1: BlockBase, block2: BlockBase) -> bool:
	if block1.core == null and block2.core == null:
		return true
	return false
