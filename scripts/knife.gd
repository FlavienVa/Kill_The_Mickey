extends StaticBody2D

@onready var interaction_area = $"Interaction Area"
@onready var sprite = $AnimatedSprite2D

func _pickup(body: Node2D) -> void:
	if body.has_method("pickup_weapon"):
		body.pickup_weapon(self)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_area.interact = Callable(self, "_collect_object")


func _collect_object():
	InteractionManager.player.has_knife = true
	_pickup(InteractionManager.player)
	queue_free()
