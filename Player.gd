extends CharacterBody3D

# Constants
const JUMP_VELOCITY : float = 45
const CROUCH_AMOUNT : float = 0.25

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Player States
var sprinting : bool = false
var crouching : bool = false

var speed : float = 4.0

@export var camera: Camera3D
@export var mouse_sensitivity: float = 0.005

@onready var animation_player : AnimationPlayer = $"Employee Model/AnimationPlayer"

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.set_current(true)

func _process(_delta: float) -> void:
	# Checking if Player is Moving
	if velocity != Vector3.ZERO:
		animation_player.play("Walking")
	else:
		animation_player.play("Idle")

func _input(event):
	# Escape Key
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Sprinting
	if Input.is_action_just_pressed("Sprint"):
		var tween : Tween = create_tween().set_parallel(true)
		sprinting = true
		speed *= 1.25

		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(camera, "fov", 90, 0.1)

	elif Input.is_action_just_released("Sprint"):
		var tween : Tween = create_tween().set_parallel(true)
		sprinting = false
		speed = 5

		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(camera, "fov", 75, 0.1)
	
	# Crouching
	if Input.is_action_just_pressed("Crouch") and not crouching:
		var tween : Tween = create_tween().set_parallel(true)
		crouching = true
		speed *= 0.75

		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "position", Vector3(position.x, position.y-CROUCH_AMOUNT, position.z), 0.4)
		tween.tween_property(self, "scale", Vector3(scale.x, scale.y-CROUCH_AMOUNT, scale.z), 0.1)

	elif Input.is_action_just_pressed("Crouch") and crouching:
		var tween : Tween = create_tween().set_parallel(true)
		crouching = false
		speed = 5

		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "position", Vector3(position.x, position.y+CROUCH_AMOUNT, position.z), 0.4)
		tween.tween_property(self, "scale", Vector3(scale.x, scale.y+CROUCH_AMOUNT, scale.z), 0.1)

	# Moving Mouse Cursor
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x, -deg_to_rad(70), deg_to_rad(70))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir : Vector2 = Input.get_vector("Left", "Right", "Forward", "Back")
	var direction : Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
