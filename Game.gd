extends Node3D

@export var Map: Node3D
@export var Entities: Node3D
@export var Players: Node3D
const EntityModels = preload("res://Entity.tscn")

var game_time: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	game_time += delta

	if roundi(game_time) % 10 == 0 and rng.randi_range(0, 100) == 0:
		spawn_entity()


func spawn_entity():
	var entity = EntityModels.instantiate()
	entity.player = Players.get_children()[rng.randi_range(0, len(Players.get_children())-1)]
	var rand_pos: Vector3 = Map.get_children()[rng.randi_range(0, len(Map.get_children())-1)].global_position
	entity.position = rand_pos + Vector3(0, 1, 0)
	Entities.add_child(entity)
	print("added entity")

# Sending Raycast from Point A -> Point B and Returning Result
func send_raycast(from: Vector3, to: Vector3) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D= PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true

	var result: Dictionary = space_state.intersect_ray(query)
	return result
