extends StaticBody2D

@onready var interaction_area = $"Interaction Area"
@onready var sprite = $AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("The apple is on the sac, I repeat, the apple is on the sac")
	interaction_area.interact = Callable(self, "_collect_object")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _collect_object():
	queue_free()
