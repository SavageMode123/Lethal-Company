extends CharacterBody3D

var speed: float = 2.5
const TRAILING_TIME: float = 5.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var rotate_timer: int = 60
var prev_rotation: int = -3
var trailingStartTime: float = 0

@export var nav: NavigationAgent3D
@export var animator: AnimationPlayer
@export var lineOfSight: RayCast3D
@export var direction_ray: RayCast3D
@export var player: CharacterBody3D

# States:
	# Idle
	# Trailing
	# Hunting
	# Attacking
var state: String = "Idle"
var lastPlayerSeenPos
var attackingStartTime: float = 0
var attackingTime: float

func _ready() -> void:
	attackingTime = animator.get_animation("Kill").length
	lineOfSight.add_exception(self)
	direction_ray.add_exception(self)
	rand_rotation()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Movement
	rotate_timer -= 1
	
	lineOfSight.target_position = lineOfSight.to_local(player.global_position)
	lineOfSight.force_raycast_update()
	
	var result = lineOfSight.get_collider()
	if result and state != "Attacking":
		if result == player:
			speed = 5.0
			state = "Hunting"
			animator.play("Hunt")
		else:
			# await get_tree().create_timer(1.0).timeout
			if state == "Hunting":
				animator.play("Hunt")
				speed = 5.0
				state = "Trailing"
				trailingStartTime = Time.get_unix_time_from_system()
			elif state != "Trailing":	
				state = "Idle"
				speed = 2.5
			
	if state == "Hunting" or state == "Trailing":
		nav.target_position = player.global_position
	else:
		var collider: Object = direction_ray.get_collider()
		
		if collider: nav.target_position = collider.global_position
		else: rand_rotation()
	
	if Time.get_unix_time_from_system() - trailingStartTime > TRAILING_TIME and state == "Trailing":
		state = "Idle"

	var nextPathPos: Vector3 = nav.get_next_path_position()
	if nextPathPos != global_position and state != "Idle":
		var prevRotation: Vector3 = rotation
		look_at(nextPathPos)
		var lookAtRotation: Vector3 = rotation
		rotation = prevRotation
		var tween := create_tween()
		tween.tween_property(self, "rotation", Vector3(0, lookAtRotation.y, 0), 0.1)
		
		rotation.x = 0
		rotation.z = 0

	var direction : Vector3 = (nextPathPos - global_position).normalized()
	
	velocity = Vector3((direction * speed).x, velocity.y, (direction * speed).z)
	
	# Kill
	if state == "Hunting" and global_position.distance_to(player.global_position) < 2:
		animator.play("Kill")
		state = "Attacking"
		attackingStartTime = Time.get_unix_time_from_system()
	
	if state == "Attacking":
		velocity = Vector3.ZERO

	if state == "Attacking" and Time.get_unix_time_from_system() - attackingStartTime > attackingTime:
		player.damage(50)
		state = "Idle"
	
	if (abs(velocity.x) < 0.1 or abs(velocity.z) < 0.1) and rotate_timer < 0 and state == "Idle":
		rand_rotation()

	move_and_slide()

func rand_rotation() -> void:
	var rotations = [-3, 3, -prev_rotation]
	rotations.shuffle()
	prev_rotation = rotations[0]

	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "rotation", Vector3(rotation.x, rotation.y+prev_rotation, rotation.z), 1)
	rotate_timer = 120

func send_raycast(from: Vector3i, to: Vector3i) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, 1, [self])
	query.collide_with_areas = true

	var result: Dictionary = space_state.intersect_ray(query)
	return result
