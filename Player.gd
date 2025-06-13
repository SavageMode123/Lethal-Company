extends CharacterBody3D

# Constants
const JUMP_VELOCITY: float = 4.5
const CROUCH_AMOUNT: float = 0.25

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Player States
var sprinting: bool = false
var crouching: bool = false

var speed: float = 5.0

@export_category("Utils")
@export var Main: Node3D
@export var ScrapHandler: Node3D

@export_category("Objects")
@export var camera: Camera3D
@export var mouse_sensitivity: float = 0.005

@export_category("Stats")
@export var max_health: float = 100.0
@export var health: float = 100.0

@onready var animation_player: AnimationPlayer = $"Employee Model/AnimationPlayer"
@onready var interactRay: RayCast3D = $"Camera/InteractRay"
@onready var inventory: Node3D = $"Inventory"

var interactablesNotIncludingScrap: Array = ["OpenButton"]
var objectInteractingWith: Object

func damage(amount: float) -> void:
	health = max(0, health - amount)

func showInteractLabel():
	$"UI/Interact".visible = true

func hideInteractLabel():
	$"UI/Interact".visible = false

func getInteracting() -> Object:
	for scrap in inventory.get_children():
		interactRay.add_exception(scrap)
	
	for scrap in camera.get_node("Viewmodel").get_children():
		interactRay.add_exception(scrap)
		
	var interacting: Object = interactRay.get_collider()
	interactRay.clear_exceptions()

	if interacting:
		# print(interacting)
		if interacting.has_meta("scrap") or interacting.name in interactablesNotIncludingScrap:
			showInteractLabel()
			return interacting

	hideInteractLabel()
	return null


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# camera.set_current(true)

func _process(_delta: float) -> void:
	# Checking if Player is Moving
	if velocity != Vector3.ZERO:
		animation_player.play("Walking")
	else:
		animation_player.play("Idle")
	
	var interacting: Object = getInteracting()
	objectInteractingWith = interacting

	# Health UI
	var healthBarSize: Vector2 = Vector2($"UI/Health".size.x * (health / max_health), $"UI/Health".size.y)
	var tween : Tween = create_tween()
	tween.tween_property($"UI/Health/Bar", "size", healthBarSize, 0.1)

	$"UI/Health/Bar".visible = !healthBarSize.x < 0.1

	# if interacting and ScrapHandler.isScrap(interacting.name):
	# 	objectInteractingWith = interacting
	
	# elif not interacting or interacting.name not in interactablesNotIncludingScrap:
	# 	hideInteractLabel())

func _input(event) -> void:
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
		speed /= 1.25

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
	
	# Interactions
	if Input.is_action_just_pressed("Interact"):
		if objectInteractingWith:
			# Picking up scrap
			if objectInteractingWith.has_meta("scrap"):
				print(objectInteractingWith.name)
				Main.remove_child(objectInteractingWith)
				# camera.add_child(objectInteractingWith)
				inventory.addScrap(objectInteractingWith)
				
				objectInteractingWith.position = Vector3(0.5, -0.5, 0)
				objectInteractingWith.freeze = true
	
	# Dropping scrap
	if Input.is_action_just_pressed("Drop"):
		var scrap: RigidBody3D = inventory.getScrap(inventory.equippedIndex)
		
		if scrap:
			var scrapPosition: Vector3 = scrap.global_position
			
			# camera.remove_child(scrap)

			inventory.removeScrap(inventory.equippedIndex)
			Main.add_child(scrap)
			scrap.visible = true
			scrap.global_position = scrapPosition
			scrap.freeze = false
	
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
	var input_dir: Vector2 = Input.get_vector("Left", "Right", "Forward", "Back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
