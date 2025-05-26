extends Control

@onready var multiplayer_hub := $MultiplayerHUB

func _ready():
	$MultiplayerHUB/Panel/VBoxContainer/HostGame.pressed.connect(_on_HostGame_pressed)
	$MultiplayerHUB/Panel/VBoxContainer/JoinGame.pressed.connect(_on_JoinGame_pressed)


func _on_HostGame_pressed():
	print("host game clicked")
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_JoinGame_pressed():
	print("join game clicked")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
