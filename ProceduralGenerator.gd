extends Node3D

@export var Hallways: Node3D
@export var Rooms: Node3D
@export var Root: Node3D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var chunk_pos: Array[Vector3] = []

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


func spawn_hallways() -> Array[Node3D]:
	var hallways: Array[Node3D] = []

	# Spawning Hallways
	for index in range(len(chunk_pos)):
		var object: Node3D = Hallways.get_node("V2").duplicate()
		object.position = chunk_pos[index]
		Root.call_deferred("add_child", object)
		hallways.append(object)
	
	await get_tree().create_timer(1.0).timeout # Waiting One Second Before Deleting Walls

	# Deleting Walls of Hallways
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
			
	return hallways


func hallway_connector(start_pos: Vector3, end_pos: Vector3, should_rand_walk: bool = false):
	var cur_pos: Vector3 = start_pos

	for i in range(int(end_pos.x + cur_pos.x + end_pos.z + cur_pos.z)):
		# Ending If Hallways are Connected
		if cur_pos == end_pos:
			break

		var endCompatiblePos: Vector3
		if end_pos.x == cur_pos.x or end_pos.z == cur_pos.z:
			endCompatiblePos = end_pos
		else:
			endCompatiblePos = Vector3(end_pos.x, end_pos.y, cur_pos.z)
		var dir: Vector3 = cur_pos.direction_to(endCompatiblePos).normalized()

		# For Every Other Iteration do Random Walk
		if (endCompatiblePos - cur_pos).length() > 8 and should_rand_walk:
			rand_walk(cur_pos, 1, dir)
			cur_pos = chunk_pos[-1]
		elif not should_rand_walk:
			var xInc: int = int(dir.x) * 4
			var zInc: int = int(dir.z) * 4

			if cur_pos + Vector3(xInc, 0, zInc) not in chunk_pos:
				chunk_pos.append(cur_pos + Vector3(xInc, 0, zInc))
			
			cur_pos = chunk_pos[-1] # Current Position Will Always Be A Valid Chunk

		
func rand_walk(cur_pos: Vector3, iterations: int, last_dir: Vector3 = Vector3.FORWARD):
	for i in range(iterations):
		var directions: Array[Vector3] = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, last_dir]
		directions.shuffle()
		var cur_dir: Vector3 = directions.pop_front()

		if cur_pos + (4 * cur_dir) in chunk_pos:
			continue

		last_dir = cur_dir
		chunk_pos.append(cur_pos + (4 * cur_dir))
		cur_pos = cur_pos + (4 * cur_dir)		

func generateMap(_origin_chunk: Vector3) -> void:
	# Spawning Hallways
	hallway_connector(Vector3(0, 0, 8), Vector3(128, 0, 128))
	print(rng.randi_range(0, len(chunk_pos)-1), len(chunk_pos))
	hallway_connector(chunk_pos[rng.randi_range(0, len(chunk_pos)-1)], Vector3.ZERO, true)
	spawn_hallways()


# Sending Raycast from Point A -> Point B and Returning Result
func send_raycast(from: Vector3, to: Vector3) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D= PhysicsRayQueryParameters3D.create(from, to, 1, [Root.get_node("Players").get_node("Player")])
	query.collide_with_areas = true

	var result: Dictionary = space_state.intersect_ray(query)
	return result
