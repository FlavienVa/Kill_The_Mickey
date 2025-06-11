extends Node

var player1: Node2D
var player2: Node2D

func register_player(player: Node2D, player_number: int):
	if player_number == 1:
		player1 = player
	elif player_number == 2:
		player2 = player

func get_player_by_name(player_name: String) -> Node2D:
	if player_name == "Player1":
		return player1
	elif player_name == "Player2":
		return player2
	return null
