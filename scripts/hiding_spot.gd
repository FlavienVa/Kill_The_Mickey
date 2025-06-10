extends StaticBody2D

@onready var interaction_area = $"Interaction Area"
@onready var sprite = $AnimatedSprite2D
@onready var hide_timer = $HideTimer
@onready var player = get_tree().get_first_node_in_group("player")


var is_hiding := false
const HIDE_DURATION := 5.0

func _ready() -> void:
	interaction_area.interact = Callable(self, "_hide")
	hide_timer.wait_time = HIDE_DURATION
	hide_timer.one_shot = true
	hide_timer.timeout.connect(_on_hide_timer_timeout)

func _hide():
	if InteractionManager.player and player.has_method("is_shy") and player.is_shy():
		if not is_hiding:
			# Start hiding
			is_hiding = true
			
			# Hide the player
			InteractionManager.playerSprite.visible = false
			InteractionManager.player.set_physics_process(false)
			
			# Start the hide timer
			hide_timer.start()
		else:
			# Unhide immediately
			_unhide_player()

func _unhide_player():
	if InteractionManager.player:
		# Show the player again
		InteractionManager.playerSprite.visible = true
		InteractionManager.player.set_physics_process(true)
		is_hiding = false
		hide_timer.stop()

func _on_hide_timer_timeout():
	if is_hiding:
		_unhide_player()
