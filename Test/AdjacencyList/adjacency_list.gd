extends Node

var graph = {
	0: {
		"neighbors": [1, 2],
		"position": Vector2(0, 0)  # 坐标
	},
	1: {
		"neighbors": [0, 3],
		"position": Vector2(1, 0)
	},
	2: {
		"neighbors": [0, 3],
		"position": Vector2(0, 1)
	},
	3: {
		"neighbors": [1, 2, 4],
		"position": Vector2(1, 1)
	},
	4: {
		"neighbors": [3, 5, 6],
		"position": Vector2(2, 1)
	},
	5: {
		"neighbors": [4],
		"position": Vector2(2, 2)
	},
	6: {
		"neighbors": [4],
		"position": Vector2(3, 1)
	}
}


# 深度优先搜索函数
func dfs(node: int, visited: Dictionary):
	visited[node] = true  # 标记为已访问
	for neighbor in graph[node]['neighbors']:
		if not visited.has(neighbor):
			dfs(neighbor, visited)
		
func check_connected_components():
	var visited = {}  # 存储访问过的节点
	var components = []  # 存储连通分量
	var new_graphs = []  # 存储新的邻接图

	# 移除节点 3 及其连接
	remove_node(3)

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


# 移除节点及其连接的函数
func remove_node(node: int):
	if graph.has(node):
		# 移除该节点的所有连接
		for neighbor in graph[node]['neighbors']:
			if graph.has(neighbor):
				graph[neighbor]['neighbors'].erase(node)  # 从邻接表中移除连接
		graph.erase(node)  # 移除节点本身

# 主函数
func _ready():
	check_connected_components()
