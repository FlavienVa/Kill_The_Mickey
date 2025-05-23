extends Node

@onready var label = %DeathCounterLabel

func _process(delta):
	label.text = "Deaths: %d" % MultiplayerManager.deaths

func become_host() -> void:
	print("you clicked become host")
	$"../MultiplayerHUB".hide()
	MultiplayerManager.become_host()

	
func join_game() -> void:
	print("you clicked join game")
	$"../MultiplayerHUB".hide()
	MultiplayerManager.join_as_player_2()
