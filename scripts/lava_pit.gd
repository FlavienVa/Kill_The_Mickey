extends Area2D

func _ready() -> void:
	# Connect the body entered signal
	print("I am a lavapit")



func _on_body_entered(body: Node2D) -> void:
	print("Just entered LavaPit")
	body.mark_dead()
