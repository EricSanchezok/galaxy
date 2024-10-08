extends Node

var vertices = []
var nearby_points = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]

	#if collision.shape is RectangleShape2D:
		#var _vertices = get_rectangle_vertices(collision.shape, graph[block]['position'] * 16 + collision.position, collision.global_rotation)
		#vertices += _vertices
		
func get_rectangle_vertices(rectangle_shape: RectangleShape2D, _position: Vector2, _rotation: float) -> Array:
	var half_extents = rectangle_shape.size / 2  # 获取矩形的半长和半宽
	var _vertices = []

	# 计算矩形的四个顶点
	var points = [
		Vector2(-half_extents.x, -half_extents.y),
		Vector2(half_extents.x, -half_extents.y),
		Vector2(half_extents.x, half_extents.y),
		Vector2(-half_extents.x, half_extents.y)
	]

	for point in points:
		# 旋转并移动到全局坐标
		var rotated_point = point.rotated(_rotation) + _position
		_vertices.append(rotated_point)

	return _vertices

func cross(o: Vector2, a: Vector2, b: Vector2) -> float:
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)

func convex_hull(points: Array) -> Array:
	var unique_points = []
	for point in points:
		if point not in unique_points:
			unique_points.append(Vector2(round(point.x), round(point.y)))
	unique_points.sort()
	print("Unique_points: ", unique_points)
	
	var lower = []
	for point in unique_points:
		while lower.size() >= 2 and cross(lower[lower.size() - 2], lower[lower.size() - 1], point) <= 0:
			lower.pop_back()
		lower.append(point)

	var upper = []
	for i in range(unique_points.size() - 1, -1, -1):
		var point = unique_points[i]
		while upper.size() >= 2 and cross(upper[upper.size() - 2], upper[upper.size() - 1], point) <= 0:
			upper.pop_back()
		upper.append(point)
	
	upper.pop_at(0)
	upper.pop_at(-1)
	
	var convex = lower + upper
	print("Convex: ", convex)

	var corrected_convex = []

	for i in range(convex.size() - 1):
		corrected_convex.append(convex[i])
		var edge_path = []

		if (convex[i + 1] - convex[i]) / 16 in nearby_points and i > 0 and i < convex.size() - 2:
			print("邻近检测: ", (convex[i + 1] - convex[i]) / 16)
			for nearby_point in nearby_points:
				var new_nearby_point = convex[i] + nearby_point * 16
				if new_nearby_point in unique_points and not is_same_point(new_nearby_point, convex[i]) and not is_same_point(new_nearby_point, convex[i + 1]) and not is_collinear(convex[i], new_nearby_point, convex[i - 1]):
					corrected_convex.append(new_nearby_point)
					print("current: ", convex[i], "new_nearby_point: ", new_nearby_point)
					edge_path = astar(unique_points, new_nearby_point, convex[i + 1])
		else:
			edge_path = astar(unique_points, convex[i], convex[i + 1])
		# print("Edge path: ", edge_path)
		for point in edge_path:
			corrected_convex.append(point)
	corrected_convex.append(convex[-1])
	print("Corrected_Convex: ", corrected_convex)
			
	
	return corrected_convex  # 返回完整的凸包
	
# A* 算法实现
func astar(points: Array, start: Vector2, end: Vector2) -> Array:
	var open_set = []  # 待评估节点
	var closed_set = []  # 已评估节点
	var came_from = {}  # 路径追踪

	# 将起始点添加到 open_set
	open_set.append(start)

	var g_score = {}  # 每个节点到起始点的代价
	var f_score = {}  # 每个节点的总评估代价

	for point in points:
		g_score[point] = INF
		f_score[point] = INF

	g_score[start] = 0
	f_score[start] = heuristic(start, end)

	while open_set.size() > 0:
		# 找到 f_score 最小的节点
		var current = get_lowest_f_score(open_set, f_score)

		# 如果到达终点
		if current == end:
			return reconstruct_path(came_from, current)

		open_set.erase(current)  # 从待评估列表中移除
		closed_set.append(current)  # 添加到已评估列表

		# 遍历相邻的点
		for neighbor in get_neighbors(current, points):
			if neighbor in closed_set:
				continue  # 如果已评估则跳过

			var tentative_g_score = g_score[current] + current.distance_to(neighbor)

			if neighbor not in open_set:
				open_set.append(neighbor)  # 如果是新邻居，添加到待评估列表
			elif tentative_g_score >= g_score[neighbor]:
				continue  # 这条路径不是最优的

			# 路径追踪
			came_from[neighbor] = current
			g_score[neighbor] = tentative_g_score
			f_score[neighbor] = g_score[neighbor] + heuristic(neighbor, end)

	return []

# 计算启发函数（直线距离）
func heuristic(a: Vector2, b: Vector2) -> float:
	return a.distance_squared_to(b)

# 获取待评估节点中 f_score 最小的节点
func get_lowest_f_score(open_set: Array, f_score: Dictionary) -> Vector2:
	var lowest = open_set[0]
	for point in open_set:
		if f_score[point] < f_score[lowest]:
			lowest = point
	return lowest

# 获取相邻节点
func get_neighbors(point: Vector2, points: Array) -> Array:
	var neighbors = []
	for p in points:
		if p != point and p.distance_to(point) <= 16:
			neighbors.append(p)
	return neighbors

# 重建路径
func reconstruct_path(came_from: Dictionary, current: Vector2) -> Array:
	var total_path = []
	# total_path.insert(0, current)
	while current in came_from:
		current = came_from[current]
		total_path.insert(0, current)
	total_path.pop_at(0)
	return total_path

func is_same_point(a: Vector2, b: Vector2) -> bool:
	return a.distance_squared_to(b) < 0.1

func is_collinear(a: Vector2, b: Vector2, c: Vector2) -> bool:
	var angle = (b - a).angle_to(c - b)
	return angle < 0.1 or abs(angle - PI) < 0.1
