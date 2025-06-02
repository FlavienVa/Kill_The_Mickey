extends StaticBody2D

@onready var interaction_area = $"Interaction Area"
@onready var sprite = $AnimatedSprite2D

@export var target_ventilation_path: NodePath
@export_enum("Up", "Down", "Left", "Right") var spawn_direction: int = 0
@export var spawn_offset: float = 200.0  # Distance from ventilation center

var target_ventilation: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_area.interact = Callable(self, "_enter_ventilation")
	add_to_group("ventilation")
	
	# Get the target ventilation node if a path is specified
	if target_ventilation_path:
		target_ventilation = get_node(target_ventilation_path)

func get_spawn_position() -> Vector2:
	var base_pos = target_ventilation.position
	match spawn_direction:
		0: # Up
			return base_pos + Vector2(0, -spawn_offset)
		1: # Down
			return base_pos + Vector2(0, spawn_offset)
		2: # Left
			return base_pos + Vector2(-spawn_offset, 0)
		3: # Right
			return base_pos + Vector2(spawn_offset, 0)
	return base_pos

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _enter_ventilation():
	if target_ventilation and InteractionManager.player:
		# Teleport the player to the target ventilation with offset
		InteractionManager.player.position = get_spawn_position()
		# Optional: Add a small delay or animation here
		await get_tree().create_timer(0.4).timeout
