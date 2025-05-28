extends Node3D

@export var Hallways: Node3D
@export var Rooms: Node3D

# var rng : RandomNumberGenerator = RandomNumberGenerator.new()

# # Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	pass # Replace with function body.

# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta: float) -> void:
# 	generate_map(Vector3.ZERO)

# func generate_map(origin_chunk: Vector3) -> void:
# 	var cur_dir : Vector3 = Vector3.FORWARD
# 	cur_dir *= rng.rand_range(-1, 1)
# 	print(cur_dir)
