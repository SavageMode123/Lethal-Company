extends CharacterBody3D

# Constants
const JUMP_VELOCITY: float = 5.0
const CROUCH_AMOUNT: float = 0.25

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Player States
var sprinting: bool = false
var crouching: bool = false

var speed: float = 4.0
var stamina: float = 100

@export_category("Utils")
@export var Scraps: Node3D

@export_category("Objects")
@export var camera: Camera3D
@export var mouse_sensitivity: float = 0.005

@export_category("Stats")
@export var max_health: float = 100.0
@export var health: float = 100.0
var dead: bool = false

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
	var interacting: Object = interactRay.get_collider()

	if interacting:
		if interacting.has_meta("scrap") or interacting.name in interactablesNotIncludingScrap:
			showInteractLabel()
			return interacting

	hideInteractLabel()
	return null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.set_current(true)

func _process(_delta: float) -> void:
	if dead:
		return

	# Checking if Player is Moving
	if velocity != Vector3.ZERO:
		if sprinting:
			stamina -= 0.2
			stamina = clamp(stamina, 0, 100)
		animation_player.play("Walking")
	else:
		animation_player.play("Idle")
		
	if not sprinting:
		stamina += 0.1
		stamina = clamp(stamina, 0, 100)

	var interacting: Object = getInteracting()
	objectInteractingWith = interacting

	var tween : Tween = create_tween()

	# Health UI
	var healthBarSize: Vector2 = Vector2($"UI/Health".size.x * (health / max_health), $"UI/Health".size.y)
	tween.tween_property($"UI/Health/Bar", "size", healthBarSize, 0.1)

	$"UI/Health/Bar".visible = !healthBarSize.x < 0.1
	
	# Stamina UI
	var staminaBarSize: Vector2 = Vector2($"UI/Stamina".size.x * (stamina / max_health), $"UI/Stamina".size.y)
	tween.tween_property($"UI/Stamina/Bar", "size", staminaBarSize, 0.1)

	$"UI/Stamina/Bar".visible = !staminaBarSize.x < 0.1

	if health <= 0 and dead == false:
		dead = true
		get_node("DeathCamera").set_current(true)
		$"UI/Dead".visible = true
		animation_player.stop()
		animation_player.play("Death")

func _input(event) -> void:
	if dead:
		return

	# Escape Key
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Sprinting
	if Input.is_action_just_pressed("Sprint") and stamina > 0.1:
		var tween: Tween = create_tween().set_parallel(true)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(camera, "fov", 100, 0.1)
		
		sprinting = true
		speed = 8

	elif Input.is_action_just_released("Sprint") or stamina <= 0.1:
		var tween : Tween = create_tween().set_parallel(true)
		sprinting = false
		speed = 4.0

		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(camera, "fov", 75, 0.1)

	if sprinting: 
		speed = 4 + (stamina/25)

	# Crouching
	if Input.is_action_just_pressed("Crouch") and not crouching:
		var tween : Tween = create_tween().set_parallel(true)
		crouching = true
		speed /=1.25

		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "position", Vector3(position.x, position.y-CROUCH_AMOUNT, position.z), 0.4)
		tween.tween_property(self, "scale", Vector3(scale.x, scale.y-CROUCH_AMOUNT, scale.z), 0.1)

	elif Input.is_action_just_pressed("Crouch") and crouching:
		var tween : Tween = create_tween().set_parallel(true)
		crouching = false
		speed = 4.0

		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "position", Vector3(position.x, position.y+CROUCH_AMOUNT, position.z), 0.4)
		tween.tween_property(self, "scale", Vector3(scale.x, scale.y+CROUCH_AMOUNT, scale.z), 0.1)

	# Interactions
	if Input.is_action_just_pressed("Interact"):
		if objectInteractingWith:
			# Picking up scrap
			if objectInteractingWith.has_meta("scrap"):
				if !inventory.isFull():
					Scraps.remove_child(objectInteractingWith)
					# camera.add_child(objectInteractingWith)
					inventory.addScrap(objectInteractingWith)
					
					
					# objectInteractingWith.freeze = true
	
	# Dropping scrap
	if Input.is_action_just_pressed("Drop"):
		var scrap: RigidBody3D = inventory.getScrap(inventory.equippedIndex)
		
		if scrap:
			var scrapPosition: Vector3 = scrap.global_position
			
			# camera.remove_child(scrap)

			inventory.removeScrap(inventory.equippedIndex)
			Scraps.add_child(scrap)
			scrap.get_node("Hitbox").disabled = false
			scrap.visible = true
			scrap.global_position = scrapPosition
			scrap.freeze = false
	
	# Moving Mouse Cursor
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x, -deg_to_rad(70), deg_to_rad(70))

func _physics_process(delta: float) -> void:
	if dead:
		return

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
