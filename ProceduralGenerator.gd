extends Node3D

@export var Hallways: Node3D
@export var Rooms: Node3D
@export var Scraps: Node3D
@export var Root: NavigationRegion3D
@export var Player: CharacterBody3D

const ScrapScene: Resource = preload('res://Scraps.tscn')
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var chunk_pos: Array[Vector3] = [Vector3.ZERO, Vector3(4, 0, 0), Vector3(-4, 0, 0), Vector3(0, 0, 4), Vector3(0, 0, -4)] # "Spawn Chunks"
var connector_pos: Array[Vector3] = [Vector3.ZERO]
var room_pos: Array[Vector3] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateMap(Vector3(0, 0, 0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func room_spawning(origin_chunk: Vector3):
	var directions: Array[Vector3] = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]

	# Determining Room Cords 
	for i in range(10, 111, 10):
		var result: Vector3 = Vector3.ZERO
		while result == Vector3.ZERO:
			result = (origin_chunk + directions[rng.randi_range(0, 1)] + directions[rng.randi_range(2, 3)])*i*2
		room_pos.append(result)

	for pos in room_pos:
		var object = Rooms.get_node("V1").duplicate()
		object.position = pos
		Root.call_deferred("add_child", object)

		# Connectors
		var connector1: Node3D = object.get_node("Connectors").get_node("Connector1")
		var connector2: Node3D = object.get_node("Connectors").get_node("Connector2")
		var connector3: Node3D = object.get_node("Connectors").get_node("Connector3")
		var connector4: Node3D = object.get_node("Connectors").get_node("Connector4")

		while not object.is_inside_tree():
			await get_tree().create_timer(0.1).timeout

		for connector in [connector1, connector2, connector3, connector4]:
			connector_pos.append((connector.global_position / 4).round() * 4)


func spawn_hallways() -> Array[Node3D]:
	var hallways: Array[Node3D] = []

	# Spawning Hallways
	for index in range(len(chunk_pos)):
		var object: Node3D = Hallways.get_node("V2").duplicate()
		object.position = chunk_pos[index]
		Root.call_deferred("add_child", object)
		hallways.append(object)
	
	for hallway in hallways:
		while not hallway.is_inside_tree():
			await get_tree().create_timer(0.1).timeout # Waiting One Second Before Deleting Walls

	# Deleting Walls of Hallways
	for i in range(len(hallways)):
		var object = hallways[i]
		
		# Deleting Walls of Hallways that Connect to Rooms
		for pos in room_pos:
			if (chunk_pos[i] - pos).length() != 8:
				continue
			
			var dir: Vector3 = chunk_pos[i].direction_to(pos)
			if dir == Vector3.BACK:
				object.get_node("Wall4").call_deferred("queue_free")
			elif dir == Vector3.FORWARD:
				object.get_node("Wall").call_deferred("queue_free")
			elif dir == Vector3.LEFT:
				object.get_node("Wall3").call_deferred("queue_free")
			elif dir == Vector3.RIGHT:
				object.get_node("Wall2").call_deferred("queue_free")
			break

		# Regular Wall Deletion
		for j in range(len(hallways)):
			if (chunk_pos[i] - chunk_pos[j]).length() != 4:
				continue

			var dir: Vector3 = chunk_pos[i].direction_to(chunk_pos[j])
			if dir == Vector3.BACK:
				object.get_node("Wall4").call_deferred("queue_free")
			elif dir == Vector3.FORWARD:
				object.get_node("Wall").call_deferred("queue_free")
			elif dir == Vector3.LEFT:
				object.get_node("Wall3").call_deferred("queue_free")
			elif dir == Vector3.RIGHT:
				object.get_node("Wall2").call_deferred("queue_free")
			
	return hallways


func hallway_connector(start_pos: Vector3, end_pos: Vector3, should_rand_walk: bool = false):
	var cur_pos: Vector3 = start_pos

	while true:
		# Ending If Hallways are Connected
		if cur_pos == end_pos:
			break

		# Random Walk
		if should_rand_walk and rng.randi_range(1, 5) != 1:
			cur_pos = rand_walk(cur_pos, 1)
			continue
		
		# Regular Hallways
		var endCompatiblePos: Vector3
		if end_pos.x == cur_pos.x or end_pos.z == cur_pos.z: endCompatiblePos = end_pos
		else: endCompatiblePos = Vector3(end_pos.x, end_pos.y, cur_pos.z)
		
		var dir: Vector3 = cur_pos.direction_to(endCompatiblePos).normalized()
		var xInc: int = int(dir.x) * 4
		var zInc: int = int(dir.z) * 4

		cur_pos += Vector3(xInc, 0, zInc)
		if cur_pos not in chunk_pos: 
			if send_raycast(cur_pos + Vector3(0, 1, 0), cur_pos - Vector3(0, 1, 0)) != {}: 
				if send_raycast(cur_pos + Vector3(1, 1, 0), cur_pos - Vector3(1, 1, 0)) == {}:
					cur_pos += Vector3(1, 0, 0)
				elif send_raycast(cur_pos + Vector3(-1, 1, 0), cur_pos - Vector3(-1, 1, 0)) == {}:
					cur_pos += Vector3(-1, 0, 0)
				elif send_raycast(cur_pos + Vector3(0, 1, 1), cur_pos - Vector3(0, 1, 1)) == {}:
					cur_pos += Vector3(0, 0, 1)
				elif send_raycast(cur_pos + Vector3(0, 1, -1), cur_pos - Vector3(0, 1, -1)) == {}:
					cur_pos += Vector3(0, 0, -1)
				else:
					continue
			chunk_pos.append(cur_pos)

		
func rand_walk(cur_pos: Vector3, iterations: int, last_dir: Vector3 = Vector3.FORWARD) -> Vector3:
	for i in range(iterations):
		var directions: Array[Vector3] = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, last_dir]
		directions.shuffle()
		var cur_dir: Vector3 = directions.pop_front()

		if cur_pos + (4 * cur_dir) in chunk_pos or send_raycast(cur_pos + Vector3(0, 1, 0), cur_pos - Vector3(0, 1, 0)) != {}:
			continue

		last_dir = cur_dir
		chunk_pos.append(cur_pos + (4 * cur_dir))
		cur_pos = cur_pos + (4 * cur_dir)
	return cur_pos

func generateMap(origin_chunk: Vector3) -> void:
	# Spawning Rooms
	await room_spawning(origin_chunk)
	chunk_pos.append_array(connector_pos)
	connector_pos.shuffle()

	# Spawning Hallways
	for i in range(0, len(connector_pos)-1, 2):
		await hallway_connector(connector_pos[i], connector_pos[i+1])

	# Random Halways
	var pointer: int = 5
	for i in range(10):
		hallway_connector(chunk_pos[pointer], Vector3.ZERO, true)
		pointer += rng.randi_range(4, 8)
		if pointer >= len(chunk_pos): pointer -= len(chunk_pos)

	await spawn_hallways()
	Root.bake_navigation_mesh(true)

	# Adding Scraps
	for pos in room_pos:
		if pos == Vector3.ZERO: continue
		var scene: Node = ScrapScene.instantiate()
		var rand_scrap: RigidBody3D = scene.get_children()[rng.randi_range(0, len(scene.get_children())-1)].duplicate()
		rand_scrap.position = pos + Vector3(0, 1, 0)
		Scraps.add_child(rand_scrap)

	pointer = 5
	for i in range(10):
		var scene: Node = ScrapScene.instantiate()
		var rand_scrap: RigidBody3D = scene.get_children()[rng.randi_range(0, len(scene.get_children())-1)].duplicate()
		rand_scrap.position = chunk_pos[pointer] + Vector3(0, 1, 0)
		if chunk_pos[pointer] != Vector3.ZERO: Scraps.add_child(rand_scrap)

		pointer += rng.randi_range(4, 8)
		if pointer >= len(chunk_pos): pointer -= len(chunk_pos)


# Sending Raycast from Point A -> Point B and Returning Result
func send_raycast(from: Vector3, to: Vector3) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D= PhysicsRayQueryParameters3D.create(from, to, 1, [Player])
	query.collide_with_areas = true

	var result: Dictionary = space_state.intersect_ray(query)
	return result
