extends Node3D

@export var Players: Node3D
@onready var openButton: Node3D = get_node("OpenButton")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for player in Players.get_children():
		var camera: Camera3D = player.get_node("Camera")
		var interactRay: RayCast3D = camera.get_node("InteractRay")
		var collider: Object = interactRay.get_collider()

		if collider:
			print(collider)
			
