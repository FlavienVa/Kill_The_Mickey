extends StaticBody2D  

@export var max_health: int = 3
var health: int = max_health
var is_dead := false

@onready var health_label = $HealthLabel

func _ready() -> void:
	add_to_group("enemy")  # optionnel si tu veux le cibler avec les attaques de zone
	update_health_label()

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount
	print("Printer took damage! Health remaining: ", health)
	update_health_label()

	# Visuel de dégât (comme pour l'ennemi)
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

	if health <= 0:
		die()

func update_health_label():
	if health_label:
		health_label.text = str(health) + "/" + str(max_health)
		
func die():
	is_dead = true
	print("Printer destroyed!")
	$Sprite2D.texture = preload("res://assets/sprites/broken-printer.png")
