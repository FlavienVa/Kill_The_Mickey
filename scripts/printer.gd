extends StaticBody2D
class_name Printer

var health := 5
var is_destroyed := false

var shake_timer := 0.0
var shake_duration := 0.2  # seconds
var shake_strength := 7.0
var original_position: Vector2

func _ready() -> void:
	original_position = position
	add_to_group("printer")
	
func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		var offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			0
	)
		position = original_position + offset
	else:
		position = original_position

func take_damage(amount: int, source_position: Vector2) -> void:
	if is_destroyed:
		return
		
	shake()
	health -= amount
	print("Printer hit! Remaining HP: ", health)

	if health <= 0:
		health = 0
		is_destroyed = true
		print("Printer destroyed!")
		$Sprite2D.texture = preload("res://assets/sprites/broken-printer.png")


func shake():
	shake_timer = shake_duration
