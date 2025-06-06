extends Node3D

@export var Hallways: Node3D
@export var Rooms: Node3D
@export var Root: Node3D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateMap(Vector3i(0, 0, 105))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func room_spawning(origin_chunk: Vector3i) -> Array[Vector3]:
	var connector_pos: Array[Vector3] = []
	var rooms: Array[Node3D] = []

	# First Room
	var room = Rooms.get_node("V1").duplicate()
	room.position = origin_chunk
	rooms.append(room)
	Root.call_deferred("add_child", room)

	# Calculating Positions of Other Rooms
	for i in range(10):
		var base_room: Node3D = rooms[rng.randi_range(0, len(rooms)-1)]
		var start_connector: Node3D = base_room.get_node("Connectors").get_node("Connector"+str(rng.randi_range(1, 4)))
		
		while not start_connector.is_inside_tree():
			await get_tree().create_timer(1.0).timeout
		
		var room_pos: Vector3i = rand_walk(start_connector.global_position, 10)[-1]
		connector_pos.append(start_connector.global_position)
		
		# Spawning
		var object: Node3D = Rooms.get_node("V1").duplicate()
		object.position = room_pos
		rooms.append(object)
		Root.call_deferred("add_child", object)

	return connector_pos


func spawn_hallways(chunk_pos: Array[Vector3i]) -> Array[Node3D]:
	var hallways: Array[Node3D] = []
	# Spawning Chunks
	for index in range(len(chunk_pos)):
		var object: Node3D = Hallways.get_node("V2").duplicate()
		object.position = chunk_pos[index]
		hallways.append(object)
		Root.call_deferred("add_child", object)

		# Deleting Walls Based on Previous and Next Hallway Position
		if index != 0:
			var prev_pos: Vector3i = chunk_pos[index-1]
			var dir: Vector3 = Vector3(prev_pos.x, prev_pos.y, prev_pos.z).direction_to(chunk_pos[index])
			
			if dir == Vector3.BACK:
				object.get_node("Wall").call_deferred("queue_free")
			elif dir == Vector3.FORWARD:
				object.get_node("Wall4").call_deferred("queue_free")
			elif dir == Vector3.LEFT:
				object.get_node("Wall2").call_deferred("queue_free")
			elif dir == Vector3.RIGHT:
				object.get_node("Wall3").call_deferred("queue_free")
		

		if index + 1 != len(chunk_pos):
			var next_pos: Vector3i = chunk_pos[index+1]
			var dir: Vector3 = Vector3(next_pos.x, next_pos.y, next_pos.z).direction_to(chunk_pos[index])
			
			if dir == Vector3.BACK:
				object.get_node("Wall").call_deferred("queue_free")
			elif dir == Vector3.FORWARD:
				object.get_node("Wall4").call_deferred("queue_free")
			elif dir == Vector3.RIGHT:
				object.get_node("Wall3").call_deferred("queue_free")
			elif dir == Vector3.LEFT:
				object.get_node("Wall2").call_deferred("queue_free")

	return hallways


func hallway_connector(start_pos: Vector3, end_pos: Vector3):
	var cur_pos = start_pos
	var hallways: Array[Node3D] = []

	var i: int = 0
	while true:
		i+=1
		if cur_pos == end_pos:
			break


		if i % 2 == 0:
			var chunk_pos: Array[Vector3i] = rand_walk(cur_pos, 5)
			# var hallway_len: int = len(hallways)
			hallways.append_array(spawn_hallways(chunk_pos))
			
			# while len(hallways) == hallway_len:
			# 	await get_tree().create_timer(1.0).timeout
			
			while not hallways[-1].is_inside_tree():
				await get_tree().create_timer(1.0).timeout
			cur_pos = hallways[-1].position
			continue

		var dir: Vector3 = Vector3(cur_pos.x, cur_pos.y, cur_pos.z).direction_to(Vector3(end_pos.x, end_pos.y, end_pos.z)).normalized()
		var chunk_pos: Array[Vector3i] = []
		
		if dir == Vector3.FORWARD:
			for j in range(1, 5): chunk_pos.append(cur_pos + Vector3(j, 0, 0))
		elif dir == Vector3.BACK:
			for j in range(1, 5): chunk_pos.append(cur_pos - Vector3(j, 0, 0))
		elif dir == Vector3.LEFT:
			for j in range(1, 5): chunk_pos.append(cur_pos - Vector3(0, 0, j))
		elif dir == Vector3.RIGHT:
			for j in range(1, 5): chunk_pos.append(cur_pos + Vector3(0, 0, j))

		# var hallway_len: int = len(hallways)
		hallways.append_array(spawn_hallways(chunk_pos))
		
		while not hallways[-1].is_inside_tree():
			await get_tree().create_timer(1.0).timeout
		cur_pos = hallways[-1].position
		print(cur_pos)

		
func rand_walk(cur_pos: Vector3i, iterations: int = 10) -> Array[Vector3i]:
	var chunk_pos: Array[Vector3i] = []
	var last_dir: Vector3i = Vector3i.FORWARD

	for i in range(iterations):
		var directions: Array[Vector3i] = [Vector3i.FORWARD, Vector3i.BACK, Vector3i.LEFT, Vector3i.RIGHT, last_dir]
		directions.shuffle()
		var cur_dir: Vector3i = directions.pop_front()

		if (cur_pos + cur_dir) * 4 in chunk_pos:
			continue

		cur_pos += cur_dir
		last_dir = cur_dir
		chunk_pos.append(cur_pos*4)
	# print(chunk_pos)
	return chunk_pos

func generateMap(origin_chunk: Vector3i) -> void:
	# var _chunk_pos: Array = hallway_spawning(origin_chunk)
	# var chunk_pos: Array[Vector3] = await room_spawning(origin_chunk)
	# print(chunk_pos)
	# for index in range(0, len(chunk_pos), 2):
	hallway_connector(Vector3i(0, 0, 0), Vector3i(10, 0, 10))

func send_raycast(from: Vector3i, to: Vector3i) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D= PhysicsRayQueryParameters3D.create(from, to, 1, [Root.get_node("Players").get_node("Player")])
	query.collide_with_areas = true

	var result: Dictionary = space_state.intersect_ray(query)
	return result
