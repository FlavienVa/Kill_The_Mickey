extends Node2D

@onready var label = $Label
const base_text = "[E] to "

# Store active areas per player
var player_active_areas = {}
var player_can_interact = {}

func register_area(area: InteractionArea, triggering_player: Node):
	print("Registering interaction area: ", area.name, " for player: ", triggering_player.name)
	
	if not player_active_areas.has(triggering_player):
		player_active_areas[triggering_player] = []
		player_can_interact[triggering_player] = true
	
	player_active_areas[triggering_player].push_back(area)
	print("Active areas count for ", triggering_player.name, ": ", player_active_areas[triggering_player].size())
	
func unregister_area(area: InteractionArea, triggering_player: Node):
	print("Unregistering interaction area: ", area.name, " for player: ", triggering_player.name)
	
	if not player_active_areas.has(triggering_player):
		return
		
	var index = player_active_areas[triggering_player].find(area)
	if index != -1:
		player_active_areas[triggering_player].remove_at(index)
	print("Active areas count for ", triggering_player.name, ": ", player_active_areas[triggering_player].size())

func _process(delta):
	# Handle interaction display for the closest player to any interaction
	var closest_player = null
	var closest_area = null
	var shortest_distance = INF
	
	# Find the closest player-area combination
	for player in player_active_areas.keys():
		if not player_can_interact.get(player, true):
			continue
			
		var areas = player_active_areas[player]
		if areas.size() > 0:
			areas.sort_custom(func(area1, area2): return _sort_by_distance_to_player(area1, area2, player))
			var distance = player.global_position.distance_to(areas[0].global_position)
			
			if distance < shortest_distance:
				shortest_distance = distance
				closest_player = player
				closest_area = areas[0]
	
	# Display label for the closest interaction
	if closest_area and closest_player:
		#print("label show")
		label.text = base_text + closest_area.action_name
		label.global_position = closest_area.global_position
		#print(label.global_position)
		label.global_position.y -= 100
		label.global_position.x -= label.size.x / 2
		label.show()
	else:
		#print("label hide")
		label.hide()

func _sort_by_distance_to_player(area1, area2, player):
	var area1_to_player = player.global_position.distance_to(area1.global_position)
	var area2_to_player = player.global_position.distance_to(area2.global_position)
	return area1_to_player < area2_to_player

func handle_player_interaction(player: Node):
	print("handle player interaction called")
	if not player_can_interact.get(player, true):
		return
		
	if not player_active_areas.has(player) or player_active_areas[player].size() == 0:
		return
	
	print("Player ", player.name, " attempting to interact")
	var areas = player_active_areas[player]
	areas.sort_custom(func(area1, area2): return _sort_by_distance_to_player(area1, area2, player))
	
	var closest_area = areas[0]
	print("Attempting to interact with: ", closest_area.name)
	
	player_can_interact[player] = false
	label.hide()
	
	await closest_area.interact.call()
	
	player_can_interact[player] = true
