# main.gd
extends Node

@onready var scene_container = $SceneContainer
var current_scene = null

func _ready():
	# Load the menu scene first
	change_scene("res://scenes/main_menu.tscn")

func change_scene(scene_path: String):
	print("current scene: ")
	print(current_scene)
	
	# Remove current scene properly
	if current_scene and is_instance_valid(current_scene):
		print("there is indeed a scene and we delete it")
		# Remove from parent first, then queue_free
		current_scene.get_parent().remove_child(current_scene)
		current_scene.queue_free()
		current_scene = null
	
	# Load new scene
	var new_scene = load(scene_path).instantiate()
	scene_container.add_child(new_scene)
	current_scene = new_scene
	
	# Notify GameManager about scene change
	var game_manager = $GameManager
	if game_manager and game_manager.has_method("_on_scene_changed"):
		game_manager._on_scene_changed(scene_path)
