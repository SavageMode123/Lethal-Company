extends CharacterBody3D

var speed: float = 3.0
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
@export var Players: Node3D
@export var navRegion: NavigationRegion3D
@onready var players: Array[Node] = Players.get_children() # Players should be Array[CharacterBody3D] but thats too specific

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
# States:
	# Idle
	# Trailing
	# Hunting
	# Attacking
var state: String = "Idle"
var attackingStartTime: float = 0
var attackingTime: float
var character: CharacterBody3D

func _ready() -> void:
	for player in players:
		add_collision_exception_with(player)

	attackingTime = animator.get_animation("Kill").length
	lineOfSight.add_exception(self)
	direction_ray.add_exception(self)
	rand_rotation()

func _physics_process(delta: float) -> void:
	for player in players:
		if player.dead: direction_ray.add_exception(player)
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Movement
	rotate_timer -= 1
	
	# Determining Movement for all Players
	for player in players:
		# Sending Ray Cast to Player
		lineOfSight.target_position = lineOfSight.to_local(player.global_position)
		lineOfSight.force_raycast_update()

		# Determining Bot State
		var result = lineOfSight.get_collider()
		if result == player and state != "Attacking":
			if not player.dead:
				speed = 6.0
				state = "Hunting"
				animator.play("Hunt")
				
				character = player
				break
		elif state == "Hunting":
			animator.play("Hunt")
			speed = 6.0
			state = "Trailing"
			trailingStartTime = Time.get_unix_time_from_system()
			break
		elif state != "Trailing":
			animator.play("Hunt")
			state = "Idle"
			speed = 3.0
			break

	# Determining Target Position
	if state == "Hunting" or state == "Trailing":
		nav.target_position = character.global_position
	else:
		# Look Around Movement if Not Hunting Player
		var collider: Object = direction_ray.get_collider()
		if collider: nav.target_position = direction_ray.get_collision_point()
		else: rand_rotation()
	
	# Setting Bot to Idle After Time Limit Expires
	if Time.get_unix_time_from_system() - trailingStartTime > TRAILING_TIME and state == "Trailing":
		state = "Idle"

	# Moving Bot to Next Path Position
	var nextPathPos: Vector3 = nav.get_next_path_position()
	if nextPathPos != global_position:
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
	
	# Killing Player
	if state == "Hunting" and global_position.distance_to(character.global_position) < 2:
		animator.play("Kill")
		state = "Attacking"
		character.damage(100)
		attackingStartTime = Time.get_unix_time_from_system()
	
	if state == "Attacking":
		velocity = Vector3.ZERO
	
	if state == "Attacking" and Time.get_unix_time_from_system() - attackingStartTime > attackingTime:
		# Teleporting
		global_position = navRegion.navigation_mesh.get_vertices()[rng.randi_range(0, len(navRegion.navigation_mesh.get_vertices()) - 1)]
		state = "Idle"
	
	# Random Movement if Bot isn't Moving
	if ((abs(velocity.x) < 0.1 and abs(velocity.z) < 0.1) or rotate_timer < 0) and state == "Idle":
		rand_rotation()

	move_and_slide()

func rand_rotation() -> void:
	var rotations = [-6, 7]
	rotations.shuffle()
	prev_rotation = rotations[0]

	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "rotation", Vector3(rotation.x, rotation.y+prev_rotation, rotation.z), 1)
	rotate_timer = 12
