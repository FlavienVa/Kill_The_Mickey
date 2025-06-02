extends StaticBody2D

@onready var interaction_area = $"Interaction Area"
@onready var sprite = $AnimatedSprite2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_area.interact = Callable(self, "_collect_object")
	
	
func _collect_object():
	var player = InteractionManager.player
	if not player:
		return
	player.has_knife = true
	visible = true
	player.pickup_weapon(self)
	
	interaction_area.set_deferred("monitoring", false)
	$"Interaction Area/CollisionShape2D".set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", true)

	
	#_pickup(InteractionManager.player)
func to_original():
	interaction_area.set_deferred("monitoring", true)
	$"Interaction Area/CollisionShape2D".set_deferred("disabled", false)
	$CollisionShape2D.set_deferred("disabled", true)
	
