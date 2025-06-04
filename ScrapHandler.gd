extends Node3D

var scrapsModelsScene: Resource = load("res://scraps.tscn")

var scrapsModelsList: Array = scrapsModelsScene.instantiate().get_children()
var scrapsModelsDictionary: Dictionary

var spawnedScraps: Dictionary = {"LargeAxle" : true}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for model in scrapsModelsList:
		scrapsModelsDictionary[model.name] = model


func isScrap(name: String):
	return name in spawnedScraps