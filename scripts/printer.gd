extends StaticBody2D
class_name Printer

var health := 5
var is_destroyed := false

func take_damage(amount: int, source_position: Vector2) -> void:
	if is_destroyed:
		return

	health -= amount
	print("Printer hit! Remaining HP: ", health)

	if health <= 0:
		health = 0
		is_destroyed = true
		print("Printer destroyed!")
		hide()  # or queue_free()
