
extends CanvasLayer


@onready var fluid_label: Label = $Panel/FluidLabel
@onready var death_label: Label = $Panel/DeathLabel

func update_fluid(fluid: int):
	fluid_label.text = "Fluid left: %d units" % fluid

func update_deaths(deaths: int):
	death_label.text = "Deaths: %d" % deaths

func show_variant_label(variant_name: String, playerid: int) -> void:
	# Check if label already exists to avoid duplicates
	if not has_node("VariantLabel"):
		var label = Label.new()
		label.name = "VariantLabel"
		if variant_name == "HappyLabel":
			if playerid == 1:
				label.text = "Press R to place traps. Traps left: 5" 
			else:
				label.text = "Press Ctrl to place traps. Traps left: 5"

			label.anchor_right = 1.0
			label.anchor_bottom = 0.1
			label.offset_left = 20
			label.offset_top = 125
			label.add_theme_font_override("font",load("res://assets/fonts/PixelOperator8.ttf"))
			add_child(label)
	

func remove_label(variant_name: String) -> void:
	if has_node("VariantLabel"):
		$VariantLabel.queue_free()

func update_traps(traps_left: int, player_id: int):
	if has_node("VariantLabel"):
		if player_id == 1:
			$VariantLabel.text = "Press R to place traps. Traps left: %d" % traps_left 
		else:
			$VariantLabel.text = "Press Ctrl to place traps. Traps left: %d" % traps_left 

func show_printer_label():
	var label = Label.new()
	label.name = "PrintLabel"
	label.text = "The printer has been destroyed! 
			You are down to your last life." 
	label.anchor_right = 1.0
	label.anchor_bottom = 0.1
	label.offset_left = 20
	label.offset_top = 175
	label.add_theme_font_override("font",load("res://assets/fonts/PixelOperator8.ttf"))
	label.add_theme_color_override("color", Color("RED"))
	add_child(label)

func show_winner_label(player_id):
	var label = Label.new()
	label.name = "WinnerLabel"
	label.text = "Player %d wins!" % player_id
	label.anchor_right = 1.0
	label.anchor_bottom = 0.1
	label.offset_left = 20
	label.offset_top = 250
	label.add_theme_font_override("font",load("res://assets/fonts/PixelOperator8.ttf"))
	label.add_theme_color_override("color", Color("GREEN"))
	add_child(label)
	
	await get_tree().create_timer(3.0).timeout
	if has_node("WinnerLabel"):
		$WinnerLabel.queue_free()
