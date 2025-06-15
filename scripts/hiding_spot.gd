extends StaticBody2D

@onready var interaction_area = $"Interaction Area"
@onready var sprite = $AnimatedSprite2D
@onready var hide_timer = $HideTimer

var is_hiding := false
var player_original_position := Vector2.ZERO  # <-- New variable to store player's position
const HIDE_DURATION := 4.0

func _ready() -> void:
	interaction_area.interact = Callable(self, "_hide")
	hide_timer.wait_time = HIDE_DURATION
	hide_timer.one_shot = true
	hide_timer.timeout.connect(_on_hide_timer_timeout)

func _hide():
	var player = interaction_area.current_player
	if player and player.has_method("is_shy") and player.is_shy():
		if not is_hiding:
			# Store the player's original position before hiding
			player_original_position = player.global_position

			# Start hiding
			is_hiding = true

			# Teleport player to hiding spot position
			player.global_position = self.global_position

			# Hide the player
			player.visible = false
			player.set_physics_process(false)

			# Start the hide timer
			hide_timer.start()
		else:
			# Unhide immediately
			_unhide_player()

func _unhide_player():
	var player = interaction_area.current_player
	if player:
		# Restore the player to their original position
		player.global_position = player_original_position

		# Show the player again
		player.visible = true
		player.set_physics_process(true)
		is_hiding = false
		hide_timer.stop()

func _on_hide_timer_timeout():
	if is_hiding:
		_unhide_player()
