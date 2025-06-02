extends CharacterBody2D

const SPEED = 1300.0
const ATTACK_COOLDOWN = 0.5
const ATTACK_DAMAGE = 1
const ATTACK_RANGE = 300.0

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

func _ready() -> void:
	# Store the initial position for respawning
	initial_position = position
	# Add the player to the "player" group
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Movement
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()
	
	velocity = input_vector * SPEED

	
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

	move_and_slide()

	# Attack logic
	if has_knife and Input.is_action_just_pressed("attack") and can_attack:
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
	print("ATTACK")
	
	# Store current attack direction based on movement or last direction
	attack_direction = facing_direction

	
	# Create attack hitbox
	var attack_hitbox = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ATTACK_RANGE, 50)  # Adjust size as needed
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
	
	# Optional: Add attack animation or effects here
	# Example: $AnimatedSprite2D.play("attack")
	
	# Wait for attack duration
	await get_tree().create_timer(0.2).timeout
	is_attacking = false
	attack_hitbox.queue_free()
	
	# Wait for cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_attack_hit(body: Node2D) -> void:
	print("There is someone under your sword")
	if body.is_in_group("enemy"):
		# Handle enemy hit
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)
		print("Hit enemy!")

func mark_dead() -> void:
	# Ta bort vapnet och lägg tillbaka det på kartan
	if current_weapon and weapon_original_parent:
		$WeaponSocket.remove_child(current_weapon)
		weapon_original_parent.add_child(current_weapon)
		current_weapon.position = weapon_original_position
		current_weapon = null
		has_knife = false

	set_physics_process(false)

	# Hide the player
	$AnimatedSprite2D.visible = false
	# Wait a short moment before respawning
	await get_tree().create_timer(1.0).timeout
	MultiplayerManager.deaths +=1
	MultiplayerManager.fluidleft -=1
	if (MultiplayerManager.fluidleft > 0) :
		respawn()
	else : 
		_game_over()


func respawn() -> void:
	# Reset position to initial spawn point
	position = initial_position
	# Re-enable player movement and input
	set_physics_process(true)
	# Make the player visible again
	$AnimatedSprite2D.visible = true
	
func _game_over() -> void:
	# Disable player movement and input
	set_physics_process(false)
	
	$AnimatedSprite2D.visible = false
	# Show game over message
	var game_over_label = %GameOverLabel
	game_over_label.text = "GAME OVER\nDeaths: %d" % MultiplayerManager.deaths
	
	# Wait a few seconds before restarting
	await get_tree().create_timer(3.0).timeout
	
	# Restart the game
	get_tree().reload_current_scene()
	
