extends Node3D

@export var Hallways: Node3D
@export var Rooms: Node3D
@export var Root: Node3D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateMap(Vector3(0, 0, 105))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func room_spawning(origin_chunk: Vector3) -> Array[Vector3]:
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
		
		# var room_pos: Vector3 = rand_walk(start_connector.global_position, 10)[-1]
		connector_pos.append(start_connector.global_position)
		
		# Spawning
		var object: Node3D = Rooms.get_node("V1").duplicate()
		# object.position = room_pos
		rooms.append(object)
		Root.call_deferred("add_child", object)

	return connector_pos


func spawn_hallways(chunk_pos: Array[Vector3]) -> Array[Node3D]:
	var hallways: Array[Node3D] = []
	# chunk_pos = [Vector3(4, 0, 0), Vector3(8, 0, 0), Vector3(12, 0, 0), Vector3(12, 0, 4)]
	# Spawning Chunks

	for index in range(len(chunk_pos)):
		var object: Node3D = Hallways.get_node("V2").duplicate()
		object.position = chunk_pos[index]
		Root.call_deferred("add_child", object)
		hallways.append(object)
	
	await get_tree().create_timer(1.0).timeout
	for index in range(len(hallways)):
		var object = hallways[index]
		# Deleting Walls Based on Previous and Next Hallway Position
		if index != 0:
			var prev_pos: Vector3 = chunk_pos[index-1]
			var dir: Vector3 = Vector3(prev_pos.x, prev_pos.y, prev_pos.z).direction_to(chunk_pos[index])

			if dir == Vector3.BACK:
				
				object.get_node("Wall").call_deferred("queue_free")
			elif dir == Vector3.FORWARD:
				object.get_node("Wall4").call_deferred("queue_free")
			elif dir == Vector3.LEFT:
				object.get_node("Wall2").call_deferred("queue_free")
			elif dir == Vector3.RIGHT:
				object.get_node("Wall3").call_deferred("queue_free")
			# else:
			# 	print(dir)

		if index + 1 != len(chunk_pos):
			var next_pos: Vector3 = chunk_pos[index+1]
			var dir: Vector3 = Vector3(next_pos.x, next_pos.y, next_pos.z).direction_to(chunk_pos[index])

			if dir == Vector3.BACK:
				object.get_node("Wall").call_deferred("queue_free")
			elif dir == Vector3.FORWARD:
				object.get_node("Wall4").call_deferred("queue_free")
			elif dir == Vector3.RIGHT:
				object.get_node("Wall3").call_deferred("queue_free")
			elif dir == Vector3.LEFT:
				object.get_node("Wall2").call_deferred("queue_free")
			# else:
			# 	print(dir)
			
	# print(str(c) + " qwoieh uiqwhedui hqwiuhe")
	# print(str(len(chunk_pos)) + " qo0weuwoqizzz")
	return hallways


func hallway_connector(start_pos: Vector3, end_pos: Vector3):
	var cur_pos = start_pos
	var hallways: Array[Node3D] = []
	
	var chunk_pos: Array[Vector3] = []

	var i: int = 0
	while true:
		i+=1
		
		if cur_pos == end_pos or i >= 100000:
			print(i)
			break

		if i % 2 == 0:
			# print("iqwei")
			# print(cur_pos, "    quiwehiqwhue")
			# var index = len(chunk_pos) - 1

			chunk_pos.append_array(rand_walk(cur_pos, 1, chunk_pos))
			# chunk_pos.remove_at(index)
			# chunk_pos.append(cur_pos)
			# var hallway_len: int = len(hallways)
			# hallways.append_array(spawn_hallways(chunk_pos))
			
			# while len(hallways) == hallway_len:
			# 	await get_tree().create_timer(1.0).timeout
			
			# while not hallways[-1].is_inside_tree():
			# 	await get_tree().create_timer(1.0).timeout
			cur_pos = chunk_pos[-1]
			continue
		
		# print(cur_pos, "    ", end_pos)
		
		# cur_pos = Vector3()
		# var lastPos = cur_pos
		
		# print(lastPos)
		var endCompatiblePos
		# (0,0,0) (12,0,12) (12,0,0)

		# (12,0,0) (12,0,12) (12, 0, 12)
		# 
		if cur_pos.x == end_pos.x or cur_pos.z == end_pos.z:
			endCompatiblePos = end_pos
		else:
			endCompatiblePos = Vector3(end_pos.x, end_pos.y, cur_pos.z)
		# print(cur_pos, "     ", endCompatiblePos)
		var dir: Vector3 = cur_pos.direction_to(endCompatiblePos).normalized()
		# print(dir)
		# print(dir, "  qweoijqwoiejqwoijiosj")
		
		# print("EEeeeeee, ", dir)
		# cur_pos = Vector3(cur_pos.x, cur_pos.y, cur_pos.z)
		# print(dir)
		var xInc: int
		var zInc: int
		
		if dir == Vector3.LEFT:
			xInc = -4
		elif dir == Vector3.RIGHT:
			xInc = 4
		else:
			xInc = 0
		
		if dir == Vector3.FORWARD:
			zInc = -4
		elif dir == Vector3.BACK:
			zInc = 4
		else:
			zInc = 0

		# cur_pos += Vector3(xInc, 0, zInc)
		# i += 1
		if cur_pos + Vector3(xInc, 0, zInc) not in chunk_pos:
			
			# print("qowiejoqwje")
			chunk_pos.append(cur_pos + Vector3(xInc, 0, zInc))
		# else:
			# print("qwoiejhqwoiehj")
		# if dir == Vector3.FORWARD:
		# 	chunk_pos.append(cur_pos - Vector3(0, 0, 4))
		# elif dir == Vector3.BACK:
		# 	chunk_pos.append(cur_pos + Vector3(0, 0, 4))
		# elif dir == Vector3.LEFT:
		# 	chunk_pos.append(cur_pos - Vector3(4, 0, 0))
		# elif dir == Vector3.RIGHT:
		# 	chunk_pos.append(cur_pos + Vector3(4, 0, 0))
		# else:
		# 	print(dir)
		
		# lastPos = chunk_pos[-1]
			
		# print(chunk_pos)
		

			# var hallway_len: int = len(hallways)
		cur_pos = chunk_pos[-1]
			# print("EEEEEEEEE ", chunk_pos)
		# hallways.append_array(spawn_hallways(chunk_pos))
	
		# while not hallways[-1].is_inside_tree():
		# 	await get_tree().create_timer(0.1).timeout
		# await get_tree().create_timer(0.1).timeout
	# print(chunk_pos)
	# print(chunk_pos)
	# for item in chunk_pos:
	# 	print(item, "        ", chunk_pos.count(item))
	# 	# if chunk_pos.count(item) > 1:
	# print(chu)
	spawn_hallways(chunk_pos)

		
func rand_walk(cur_pos: Vector3, iterations: int, prevChunks) -> Array[Vector3]:
	var chunk_pos: Array[Vector3] = []
	var last_dir: Vector3 = Vector3.FORWARD
	# cur_pos = prevChunks[rng.randi_range(0, len(prevChunks) - 1)]
	for i in range(iterations):
		var directions: Array[Vector3] = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, last_dir]
		directions.shuffle()
		var cur_dir: Vector3 = directions.pop_front()

		if cur_pos + (4 * cur_dir) in prevChunks or cur_pos + (4 * cur_dir) in chunk_pos: # Parenthesis change?
			continue

		# cur_pos += cur_dir

		last_dir = cur_dir
		
		# print(cur_pos, "qwoehj")
		chunk_pos.append(cur_pos + (4 * cur_dir))
		cur_pos = cur_pos + (4 * cur_dir)

	# print(chunk_pos, "     RANDWALk")
	# print(chunk_pos)
	# print(chunk_pos)
	return chunk_pos

func generateMap(origin_chunk: Vector3) -> void:
	# var _chunk_pos: Array = hallway_spawning(origin_chunk)
	# var chunk_pos: Array[Vector3] = await room_spawning(origin_chunk)
	# print(chunk_pos)
	# for index in range(0, len(chunk_pos), 2):
	hallway_connector(Vector3(0, 0, 8), Vector3(128, 0, 12))

func send_raycast(from: Vector3, to: Vector3) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D= PhysicsRayQueryParameters3D.create(from, to, 1, [Root.get_node("Players").get_node("Player")])
	query.collide_with_areas = true

	var result: Dictionary = space_state.intersect_ray(query)
	return result
