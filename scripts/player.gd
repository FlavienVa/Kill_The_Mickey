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
	move_and_slide()

	# Attack logic
	if has_knife and Input.is_action_just_pressed("attack") and can_attack:
		perform_attack()

func perform_attack():
	if not can_attack or not has_knife:
		return
		
	can_attack = false
	is_attacking = true
	print("ATTACK")
	
	# Store current attack direction based on movement or last direction
	if velocity != Vector2.ZERO:
		attack_direction = velocity.normalized()
	
	# Create attack hitbox
	var attack_hitbox = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ATTACK_RANGE, 50)  # Adjust size as needed
	collision_shape.shape = shape
	attack_hitbox.add_child(collision_shape)
	
	# Position the hitbox in front of the player
	attack_hitbox.position = attack_direction * (ATTACK_RANGE / 2)
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
	# Disable player movement and input
	set_physics_process(false)
	# Hide the player
	visible = false
	# Wait a short moment before respawning
	await get_tree().create_timer(1.0).timeout
	MultiplayerManager.deaths +=1
	respawn()

func respawn() -> void:
	# Reset position to initial spawn point
	position = initial_position
	# Re-enable player movement and input
	set_physics_process(true)
	# Make the player visible again
	visible = true
