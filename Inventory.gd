extends Node3D

@export var UI: Control
@export var viewmodel: Node3D

@onready var inventoryUI: BoxContainer = UI.get_node("Inventory")

var inventory: Array = [null, null, null, null]
var availableIndexes: Array = [0, 1, 2, 3]
var equippedIndex: int = 0

func getScrap(index: int):
	return inventory[index]

func addScrap(scrap: RigidBody3D):
	if len(availableIndexes) > 0:
		var availableIndex: int = availableIndexes[0]
		print(availableIndex)
		inventory[availableIndex] = scrap
		availableIndexes.remove_at(0)

		add_child(scrap)
		var scrapDuplicate: RigidBody3D = scrap.duplicate()
		scrap.freeze = true
		scrap.visible = false
		inventoryUI.get_node(str(availableIndex)).get_node("Image").visible = true

		viewmodel.add_child(scrapDuplicate)
		scrapDuplicate.position = Vector3(0.5, -0.5, 0)
		scrapDuplicate.freeze = true

func removeScrap(index: int):
	if index < len(inventory):
		var scrap: RigidBody3D = getScrap(index)
		if scrap != null:
			inventory[index] = null
			availableIndexes.append(index)
			availableIndexes.sort()
			
			inventoryUI.get_node(str(index)).get_node("Image").visible = false
			
			for part in viewmodel.get_children():
				part.queue_free()

			remove_child(scrap)

func _process(_delta: float) -> void:
	var equippedInventorySlotUI: Panel = inventoryUI.get_node(str(equippedIndex))
	var sizeTween = create_tween()
	sizeTween.tween_property(equippedInventorySlotUI, "scale", Vector2(1.1, 1.1), 0.1)

	for slotUI in inventoryUI.get_children():
		if slotUI == equippedInventorySlotUI:
			continue
		
		sizeTween.tween_property(equippedInventorySlotUI, "scale", Vector2(1, 1), 0.1) 

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("CycleInventoryRight"):
		equippedIndex = (equippedIndex + 1) % 4
