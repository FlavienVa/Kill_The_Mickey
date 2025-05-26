extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("pickup_weapon"):
		body.pickup_weapon(self)
