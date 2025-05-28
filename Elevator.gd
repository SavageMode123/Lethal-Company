extends Node3D

@export var Players: Node3D
@onready var openButton: StaticBody3D = get_node("OpenButton")

@onready var door: StaticBody3D = get_node("Door")
@onready var doorAnimationPlayer: AnimationPlayer = door.get_node("AnimationPlayer")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var canPressOpenButton: bool = false
var doorOpen: bool = false

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Interact"):
		if canPressOpenButton == true:
			if doorOpen == false:
				doorAnimationPlayer.play("ElevatorDoorOpen")
			else:
				doorAnimationPlayer.play("ElevatorDoorOpen", -1, -1, true)
				
			doorOpen = !doorOpen

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for player in Players.get_children():
		var collider: Object = player.getInteracting()
		
		var playerUI: Control = player.get_node("UI")
		var interactLabel: Label = playerUI.get_node("Interact")

		if collider and collider.name == "OpenButton":
			interactLabel.visible = true
			canPressOpenButton = true
		else:
			interactLabel.visible = false
			canPressOpenButton = false
