extends Node3D

@export var Hallways: Node3D
@export var Rooms: Node3D
@export var Root: Node3D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateMap(Vector3i(0, 7, 0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func generateMap(origin_chunk: Vector3i) -> void:
	var chunk_pos: Array = [origin_chunk]
	var cur_pos: Vector3i = origin_chunk
	var cur_dir: Vector3i = Vector3i.FORWARD
	var last_dir: Vector3i = Vector3i.FORWARD

	for i in range(100):
		var directions: Array[Vector3i] = [Vector3i.FORWARD, Vector3i.BACK, Vector3i.LEFT, Vector3i.RIGHT, last_dir]
		directions.shuffle()
		cur_dir = directions.pop_front()

		if cur_pos + cur_dir in chunk_pos:
			continue

		cur_pos += cur_dir
		last_dir = cur_dir
		chunk_pos.append(cur_pos)
	
	for index in range(len(chunk_pos)):
		var object: Node3D = Hallways.get_node("V2").duplicate()
		object.position = chunk_pos[index]
		Root.call_deferred("add_child", object)

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

			print(dir)
			# var result: Dictionary = send_raycast(prev_pos, chunk_pos[index])
			# if result != {}:
			# 	print(result.collider)
			# 	result.collider.queue_free()
		

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

			print(dir)
			# var result: Dictionary = send_raycast(chunk_pos[index], next_pos)
			# if result != {}:
			# 	print(result.collider)
			# 	result.collider.queue_free()
		# print(object.position)

func send_raycast(from: Vector3i, to: Vector3i) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D= PhysicsRayQueryParameters3D.create(from, to, 1, [Root.get_node("Players").get_node("Player")])
	query.collide_with_areas = true

	var result: Dictionary = space_state.intersect_ray(query)
	return result
