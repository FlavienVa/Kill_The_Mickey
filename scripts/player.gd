extends CharacterBody2D

const SPEED = 1300.0
const ATTACK_COOLDOWN = 0.5
const ATTACK_DAMAGE = 1
const ATTACK_RANGE = 300.0

@export var player_id: int = 1  # 1 for Player 1, 2 for Player 2

var has_knife := false
var attack_cooldown := ATTACK_COOLDOWN
var can_attack := true
var initial_position: Vector2
var attack_direction := Vector2.RIGHT
var is_attacking := false

var current_weapon: Node2D = null
var weapon_original_parent: Node = null
var weapon_original_position: Vector2 = Vector2.ZERO

var facing_direction := Vector2.RIGHT

# Player-specific stats
var deaths := 0
var fluid_left := 100

@onready var _animated_sprite := $AnimatedSprite2D

# Preload or load variant resources
var sprite_variants = {
	"happy": preload("res://player/variants/happy.tres"),
	"angry": preload("res://player/variants/angry.tres"),
	"smart": preload("res://player/variants/smart.tres"),
	"shy": preload("res://player/variants/shy.tres") 
}
var variant_keys = sprite_variants.keys()

@onready var _footstep_audio := $FootStepAudio
@onready var _footstep_timer := $FootStepTimer

# Footstep sounds
var footstep_sounds = [
	preload("res://assets/sounds/Footsteps 1.wav"),
	preload("res://assets/sounds/Footsteps 2.wav"),
	preload("res://assets/sounds/Footsteps 3.wav")
]

func _ready() -> void:
	# Store the initial position for respawning
	initial_position = position
	# Add the player to the "player" group
	add_to_group("player")
	
	# Set different spawn positions for different players
	if player_id == 2:
		position.x += 100  # Offset Player 2 spawn position
	
	# Load a random variant at startup
	randomize()
	set_sprite_variant(variant_keys[randi() % variant_keys.size()])
	
	# Set player name for identification
	name = "Player" + str(player_id)

func set_sprite_variant(variant_name: String) -> void:
	if sprite_variants.has(variant_name):
		_animated_sprite.sprite_frames = sprite_variants[variant_name]
	else:
		push_error("Variant '%s' not found!" % variant_name)

#func _input(event):
	#if event.is_action_pressed("interact"):
		#InteractionManager.handle_player_interaction(self)

func _physics_process(delta: float) -> void:
	# Movement with player-specific input
	var input_vector := Vector2.ZERO
	
	if player_id == 1:
		# Player 1 controls (WASD)
		input_vector.x = Input.get_action_strength("p1_move_right") - Input.get_action_strength("p1_move_left")
		input_vector.y = Input.get_action_strength("p1_move_down") - Input.get_action_strength("p1_move_up")
	elif player_id == 2:
		# Player 2 controls (Arrow keys)
		input_vector.x = Input.get_action_strength("p2_move_right") - Input.get_action_strength("p2_move_left")
		input_vector.y = Input.get_action_strength("p2_move_down") - Input.get_action_strength("p2_move_up")
	
	input_vector = input_vector.normalized()
	velocity = input_vector * SPEED

	# Handle sprite flipping and weapon positioning
	if input_vector.x > 0:
		$AnimatedSprite2D.flip_h = false
		facing_direction = Vector2.RIGHT
		if has_knife and current_weapon:
			current_weapon.scale.x = abs(current_weapon.scale.x)
	elif input_vector.x < 0:
		$AnimatedSprite2D.flip_h = true
		facing_direction = Vector2.LEFT
		if has_knife and current_weapon:
			current_weapon.scale.x = -abs(current_weapon.scale.x)
	elif input_vector.y != 0:
		facing_direction = Vector2(0, input_vector.y)
		
	# Play animation and footstep sound
	if input_vector != Vector2.ZERO:
		$AnimatedSprite2D.play("run")
		if not _footstep_timer.is_stopped():
			pass  # already playing
		else:
			_footstep_timer.start()
	else:
		$AnimatedSprite2D.play("idle")
		_footstep_timer.stop()

	move_and_slide()

	# Attack logic with player-specific input
	var attack_input = ""
	if player_id == 1:
		attack_input = "p1_attack"
	elif player_id == 2:
		attack_input = "p2_attack"
	
	if has_knife and Input.is_action_just_pressed(attack_input) and can_attack:
		perform_attack()

func pickup_weapon(weapon: Node2D) -> void:
	has_knife = true
	current_weapon = weapon
	weapon_original_parent = weapon.get_parent()
	weapon_original_position = weapon.position

	if weapon.get_parent():
		weapon.get_parent().remove_child(weapon)

	$WeaponSocket.add_child(weapon)
	weapon.position = Vector2.ZERO

func perform_attack():
	if not can_attack or not has_knife:
		return
		
	can_attack = false
	is_attacking = true
	print("Player %d ATTACK" % player_id)
	
	# Store current attack direction based on movement or last direction
	attack_direction = facing_direction
	
	# Create attack hitbox
	var attack_hitbox = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ATTACK_RANGE, 50)
	collision_shape.shape = shape
	attack_hitbox.add_child(collision_shape)
	
	# Position the hitbox in front of the player
	attack_hitbox.position = attack_direction * (ATTACK_RANGE / 2)
	attack_hitbox.rotation = attack_direction.angle()
	add_child(attack_hitbox)
	
	# Connect to detect hits
	attack_hitbox.body_entered.connect(_on_attack_hit)
	
	# Visual feedback
	$AttackCooldownTimer.start()
	$AttackCooldownTimer.wait_time = attack_cooldown
	
	# Wait for attack duration
	await get_tree().create_timer(0.2).timeout
	is_attacking = false
	attack_hitbox.queue_free()
	
	# Wait for cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_attack_hit(body: Node2D) -> void:
	print("Player %d hit something with sword" % player_id)
	if body.is_in_group("enemy"):
		# Handle enemy hit
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)
		print("Player %d hit enemy!" % player_id)
	elif body.is_in_group("player") and body != self:
		# Handle player vs player combat
		if body.has_method("take_damage_from_player"):
			body.take_damage_from_player(ATTACK_DAMAGE, self)
		print("Player %d hit Player %d!" % [player_id, body.player_id])

func take_damage_from_player(damage: int, attacker: Node2D) -> void:
	print("Player %d took damage from Player %d" % [player_id, attacker.player_id])
	mark_dead()

func mark_dead() -> void:
	# Return weapon to map
	if current_weapon and weapon_original_parent:
		$WeaponSocket.remove_child(current_weapon)
		weapon_original_parent.add_child(current_weapon)
		current_weapon.position = weapon_original_position
		current_weapon = null
		has_knife = false

	set_physics_process(false)
	$AnimatedSprite2D.visible = false
	
	# Wait before respawning
	await get_tree().create_timer(1.0).timeout
	deaths += 1
	fluid_left -= 1
	
	if fluid_left > 0:
		respawn()
	else:
		_game_over()

func respawn() -> void:
	# Reset position to initial spawn point
	position = initial_position
	# Re-enable player movement and input
	set_physics_process(true)
	# Change the variant
	set_sprite_variant(variant_keys[randi() % variant_keys.size()])
	# Make the player visible again
	$AnimatedSprite2D.visible = true
	
func _game_over() -> void:
	# Disable player movement and input
	set_physics_process(false)
	$AnimatedSprite2D.visible = false
	
	# Show game over message for this player
	print("Player %d GAME OVER - Deaths: %d" % [player_id, deaths])
	
	# You might want to handle this differently for split screen
	# Maybe show a game over overlay for just this player's viewport
	
	# Check if both players are dead before restarting
	var all_players = get_tree().get_nodes_in_group("player")
	var living_players = 0
	for player in all_players:
		if player.fluid_left > 0:
			living_players += 1
	
	if living_players == 0:
		# All players are dead, restart the game
		await get_tree().create_timer(3.0).timeout
		get_tree().reload_current_scene()

func _on_foot_step_timer_timeout() -> void:
	if velocity.length() > 0:
		var random_index = randi() % footstep_sounds.size()
		$FootStepAudio.stream = footstep_sounds[random_index]
		$FootStepAudio.pitch_scale = randf_range(0.95, 1.05)
		_footstep_audio.play()

# Getter functions for UI updates
func get_deaths() -> int:
	return deaths

func get_fluid_left() -> int:
	return fluid_left
