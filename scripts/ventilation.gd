extends StaticBody2D

@onready var interaction_area = $"Interaction Area"
@onready var sprite = $AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_area.interact = Callable(self, "_enter_ventilation")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _enter_ventilation():
	InteractionManager.player.position
	queue_free()
