extends Area2D

func _on_body_entered(body: Node2D) -> void:
	body.take_damage(1, global_position) # Replace with function body.
