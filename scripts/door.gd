extends StaticBody2D

@onready var _collision = $CollisionShape2D
@onready var interaction_area = $"Interaction Area"
@onready var _audio = $AudioStreamPlayer2D
@onready var _sprite = $Sprite2D

@onready var player = get_tree().get_first_node_in_group("player")



var is_open = true
var is_destroyed = false
var health = 10


func _ready():
	add_to_group("doors")
	randomize()
	if randi_range(0, 1) == 1:
		_sprite.frame = 1 
		_collision.disabled = true
	else:
		_sprite.frame = 0
		_collision.disabled = false
		is_open = false
	interaction_area.interact = Callable(self, "_open")


func _open():
	var player = interaction_area.current_player
	if player and not is_destroyed:
		if not is_open and player.has_method("is_smart") and player.is_smart():
			# Open the door
			is_open = true
			_audio.play()

		elif player.has_method("is_smart") and player.is_smart():
			#Close the door
			is_open = false
			_audio.play()

	if is_open:
		_sprite.frame = 1 
		_collision.disabled = true  # disable collision when open
	else: 
		_sprite.frame = 0
		_collision.disabled = false  
	
func take_damage() -> void:
	if is_destroyed:
		return
	# Visual feedback
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	player = interaction_area.current_player
	if player.has_method("is_angry") and player.is_angry():
		health -= 10
	else:
		health -= 1
	print(health)
	if health <= 0:
		is_destroyed = true
		_sprite.frame = 2
		_collision.disabled = true
		interaction_area.queue_free()
