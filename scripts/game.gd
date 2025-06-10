# game_scene.gd
extends Control

@onready var grid_container = $GridContainer
@onready var viewport1 = $GridContainer/SubViewportContainer/SubViewport
@onready var viewport2 = $GridContainer/SubViewportContainer2/SubViewport
@onready var camera1 = $GridContainer/SubViewportContainer/SubViewport/Camera2D
@onready var camera2 = $GridContainer/SubViewportContainer2/SubViewport/Camera2D

var player1: Node2D
var player2: Node2D

func _ready():
	# Setup grid container for split screen
	grid_container.columns = 2  # For horizontal split
	grid_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Share the world between viewports so both see the same level
	viewport2.world_2d = viewport1.world_2d
	
	# Find players and assign cameras
	setup_players_and_cameras()

func setup_players_and_cameras():
	# Wait for players to be ready
	await get_tree().process_frame
	
	# Find players in the scene
	var players = get_tree().get_nodes_in_group("player")
	if players.size() >= 2:
		player1 = players[0]
		player2 = players[1]
		
		# Assign camera targets
		camera1.target = player1
		camera2.target = player2
	else:
		print("Not enough players found for split screen")
