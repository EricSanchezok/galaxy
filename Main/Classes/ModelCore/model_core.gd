class_name ModelCore
extends RigidBody2D

@onready var collision_polygon_2d_convex: CollisionPolygon2D = $CollisionPolygon2D_Convex
@onready var marker_2d_mass: Marker2D = $Marker2D_Mass

var graph = {}
var total_mass = 0.0
var mass_center = Vector2.ZERO

signal core_free(core: ModelCore)

func add_block(block: BlockBase) -> void:
	# print("Add block: ", block)
	block.core = self
	block.transition_state(BlockBase.State.WITH_CORE)

	graph[block] = {}
	graph[block]['neighbors'] = []
	graph[block]['position'] = Vector2.ZERO

	if len(graph) > 1:
		var local_position = (block.global_position - graph.keys()[0].global_position) / 16.0
		local_position = local_position.rotated(-rotation)
		graph[block]['position'] = Vector2(round(local_position.x), round(local_position.y))
		# print("pos_diff: ", block.global_position - graph.keys()[0].global_position, "local_pos: ", local_position, "pos: ", graph[block]['position'])

		for node in graph.keys():
			if node == block or graph[node]['position'].distance_squared_to(graph[block]['position']) > 1.1:
				continue
			for my_combine_marker in block.combining_markers.get_children():
				for combine_marker in node.combining_markers.get_children():
					var dis_squar = my_combine_marker.global_position.distance_squared_to(combine_marker.global_position)
					if dis_squar <= 1.0:
						if node not in graph[block]['neighbors']:
							graph[block]['neighbors'].append(node)
						if block not in graph[node]['neighbors']:
							graph[node]['neighbors'].append(block)
						my_combine_marker.lock = true
						combine_marker.lock = true
					
	block.reparent(self, true)
	corrected_transform(block)
	
	var new_collision_shape = CollisionShape2D.new()
	new_collision_shape.shape = block.collision_shape_2d_phy.shape.duplicate()
	new_collision_shape.position = block.position
	new_collision_shape.rotation = block.rotation
	new_collision_shape.debug_color = Color(Color.HOT_PINK, 0.5)
	add_child(new_collision_shape)
	
	graph[block]['collision_shape'] = new_collision_shape

	total_mass += block.mass
	mass = total_mass

	mass_center += block.position * block.mass
	center_of_mass = mass_center / total_mass
	
	marker_2d_mass.position = center_of_mass

	block.block_combine_finished.emit()
	
func delete_block(block: BlockBase) -> void:
	print("Delete Block: ", block)
	block.core == null
	
	total_mass -= block.mass
	mass = total_mass
	
	mass_center -= block.position * block.mass
	center_of_mass = mass_center / total_mass
	
	marker_2d_mass.position = center_of_mass
	
	graph[block]['collision_shape'].queue_free()
	block.queue_free()
	
	for neighbor in graph[block]['neighbors']:
		if graph.has(neighbor):
			graph[neighbor]['neighbors'].erase(block)  # 从邻接表中移除连接
	graph.erase(block)
	
	if check_alone():
		var _block = graph.keys()[0]
		_block.reparent(get_tree().root, true)
		_block.transition_state(BlockBase.State.SINGLE)
		core_free.emit(self)
		queue_free()
		return
	
	var new_graphs: Array = check_connected_components()
	
	if len(new_graphs) == 1:
		return
		
	for _graph in new_graphs:
		CoreManager.new_core(_graph)
	
	core_free.emit(self)
	queue_free()

			
func check_alone() -> bool:
	if len(graph) == 1:
		return true
	return false
			
# 深度优先搜索函数
func dfs(node: BlockBase, visited: Dictionary):
	visited[node] = true  # 标记为已访问
	for neighbor in graph[node]['neighbors']:
		if not visited.has(neighbor):
			dfs(neighbor, visited)
		
func check_connected_components() -> Array:
	var visited = {}  # 存储访问过的节点
	var components = []  # 存储连通分量
	var new_graphs = []  # 存储新的邻接图

	# 遍历所有节点
	for node in graph.keys():
		if not visited.has(node):
			var component = []  # 创建新的组件
			dfs(node, visited)  # 执行 DFS
			
			# 记录当前组件
			for v in visited.keys():
				if visited[v]:
					component.append(v)  # 添加到当前组件
			
			components.append(component)  # 添加到组件列表
			
			# 创建新的邻接图
			var new_graph = {}  # 新的邻接图
			for v in component:
				new_graph[v] = {
					"neighbors": [],
					"position": graph[v]["position"]  # 复制坐标信息
				}
				for neighbor in graph[v]["neighbors"]:
					if neighbor in component:  # 只保留在当前组件内的连接
						new_graph[v]["neighbors"].append(neighbor)

			new_graphs.append(new_graph)  # 添加新的邻接图
			
			# 在这里重置 visited 的访问状态
			for v in component:
				visited[v] = false  # 重置当前组件内的节点状态

	# 打印连通分量
	for i in range(components.size()):
		print("Component %d: %s" % [i, str(components[i])])
		
	# 打印新的邻接图
	for i in range(new_graphs.size()):
		print("New Graph %d: %s" % [i, str(new_graphs[i])])
		
	return new_graphs

	
func corrected_transform(block: BlockBase) -> void:
	if block not in graph:
		return
	block.position = graph[block]['position'] * 16.0
	block.rotation_degrees = round(fmod(block.rotation_degrees, 360.0) / 90) * 90

func print_graph() -> void:
	for block in graph.keys():
		var block_info = "Block: %s\n" % [str(block)]
		var position_info = "  Position: %s\n" % [str(graph[block]['position'])]
		var neighbors_info = "  Neighbors: ["

		# 收集邻接节点的信息
		for neighbor in graph[block]['neighbors']:
			neighbors_info += str(neighbor) + ", "
		
		# 移除最后的逗号和空格，并添加闭合方括号
		if graph[block]['neighbors'].size() > 0:
			neighbors_info = neighbors_info.substr(0, neighbors_info.length() - 2)
		neighbors_info += "]\n"

		# 打印块的信息
		print(block_info + position_info + neighbors_info)
