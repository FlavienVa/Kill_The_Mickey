extends Area2D




func _on_body_entered(body: Node2D) -> void:
	body.has_knife = true
	queue_free()  # Remove knife from scene
