extends Node3D

@export var Hallways: Node3D
@export var Rooms: Node3D
@export var Root: Node3D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateMap(Vector3i(0, 0, 0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func room_spawning(origin_chunk: Vector3i) -> Array[Vector3]:
	var room: Node3D = Rooms.get_node("V1").duplicate()
	room.position = origin_chunk
	var rooms: Array[Node3D] = [room]
	var chunk_pos: Array[Vector3] = []

	# for i in range(rng.randi_range(2, 5)):
	for i in range(-5, 5):
		var rand_connector: Node3D = rooms[-1].get_node("Connectors").get_node("Connector"+str(rng.randi_range(1, 4)))
		var rand_pos : Vector3 = Vector3(rand_connector.position.x + (rng.randi_range(-10, 10)*i), rand_connector.position.y, rand_connector.position.z + (rng.randi_range(-10, 10)*i))
		
		var object: Node3D = room.duplicate()
		object.position = rand_pos
		Root.call_deferred("add_child", object)

	return chunk_pos

func hallway_spawning(origin_chunk: Vector3i) -> Array[Vector3i]:
	var chunk_pos: Array[Vector3i] = [origin_chunk]
	var cur_pos: Vector3i = origin_chunk
	var cur_dir: Vector3i = Vector3i.FORWARD
	var last_dir: Vector3i = Vector3i.FORWARD
	
	# Getting Chunk Positions
	for i in range(1000):
		var directions: Array[Vector3i] = [Vector3i.FORWARD, Vector3i.BACK, Vector3i.LEFT, Vector3i.RIGHT, last_dir]
		directions.shuffle()
		cur_dir = directions.pop_front()

		if (cur_pos + cur_dir) *4 in chunk_pos:
			continue

		cur_pos += cur_dir
		last_dir = cur_dir
		chunk_pos.append(cur_pos*4)
	

	# Spawning Chunks
	for index in range(len(chunk_pos)):
		var object: Node3D = Hallways.get_node("V2").duplicate()
		object.position = chunk_pos[index]
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

	return chunk_pos

func generateMap(origin_chunk: Vector3i) -> void:
	var _chunk_pos: Array = hallway_spawning(origin_chunk)
	# room_spawning(origin_chunk)

func send_raycast(from: Vector3i, to: Vector3i) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D= PhysicsRayQueryParameters3D.create(from, to, 1, [Root.get_node("Players").get_node("Player")])
	query.collide_with_areas = true

	var result: Dictionary = space_state.intersect_ray(query)
	return result