extends Node

@onready var label = %DeathCounterLabel

func _process(delta):
	var fluid = MultiplayerManager.fluidleft
	var deaths = MultiplayerManager.deaths
	label.text = "Deaths: %d / Fluid left : %d Units" % [deaths, fluid]	

func become_host() -> void:
	print("you clicked become host")
	$"../MultiplayerHUB".hide()
	MultiplayerManager.become_host()

	
func join_game() -> void:
	print("you clicked join game")
	$"../MultiplayerHUB".hide()
	MultiplayerManager.join_as_player_2()
