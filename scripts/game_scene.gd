# game_scene.gd
extends Control

@onready var grid_container = $GridContainer
@onready var viewport1 = $GridContainer/SubViewportContainer/SubViewport
@onready var viewport2 = $GridContainer/SubViewportContainer2/SubViewport
@onready var camera1 = $GridContainer/SubViewportContainer/SubViewport/Camera2D
@onready var camera2 = $GridContainer/SubViewportContainer2/SubViewport/Camera2D
@onready var game_world = $Game

var player1: Node2D
var player2: Node2D

# Load the UI scene
var PlayerUI = preload("res://scenes/PlayerUI.tscn")  # adjust path as needed


func _ready():
	# Setup grid container for split screen
	grid_container.columns = 2  # For horizontal split
	grid_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# CRITICAL: Share the same world between both viewports
	viewport2.world_2d = viewport1.world_2d
	
	# Move the entire game world INTO the first viewport
	remove_child(game_world)
	viewport1.add_child(game_world)
	
	# Setup cameras and UI
	await setup_players_and_cameras_and_ui()


func setup_players_and_cameras_and_ui() -> void:
	await get_tree().process_frame
	
	player1 = game_world.get_node("Player1")
	player2 = game_world.get_node("Player2")
	
	if player1 and player2:
		camera1.target = player1
		camera2.target = player2
		player1.player_id = 1
		player2.player_id = 2
		
		# Instantiate and assign Player 1 UI
		var ui1 = PlayerUI.instantiate()
		viewport1.add_child(ui1)
		player1.ui = ui1  # make sure this export exists in Player.gd

		# Instantiate and assign Player 2 UI
		var ui2 = PlayerUI.instantiate()
		viewport2.add_child(ui2)
		player2.ui = ui2

		print("Split screen cameras and UI setup complete")
	else:
		print("Players not found in GameWorld")
