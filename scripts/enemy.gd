extends CharacterBody2D

# Enemy properties
const SPEED = 400.0
const DETECTION_RADIUS = 300.0
const ATTACK_RANGE = 50.0
const ATTACK_COOLDOWN = 1.5

# Enemy stats
var health := 3
var max_health := 3
var is_dead := false
var can_attack := true
var player = null

# Movement variables
var direction := Vector2.ZERO
var wander_timer := 0.0
var wander_direction := Vector2.ZERO

func _ready() -> void:
	# Add to enemy group for attack detection
	add_to_group("enemy")
	# Start wandering
	start_wandering()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Find player if not already found
	if player == null:
		find_player()
	
	# Update movement
	if player != null:
		handle_player_detection()
	else:
		handle_wandering(delta)
	
	# Apply movement
	move_and_slide()

func find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func handle_player_detection() -> void:
	if player == null:
		return
		
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= DETECTION_RADIUS:
		# Move towards player
		direction = (player.global_position - global_position).normalized()
		velocity = direction * SPEED
		
		# Attack if in range
		if distance_to_player <= ATTACK_RANGE and can_attack:
			perform_attack()
	else:
		# Return to wandering if player is too far
		handle_wandering(get_process_delta_time())

func handle_wandering(delta: float) -> void:
	wander_timer -= delta
	
	if wander_timer <= 0:
		start_wandering()
	
	velocity = wander_direction * (SPEED * 0.5)

func start_wandering() -> void:
	# Generate random direction
	var random_angle = randf_range(0, 2 * PI)
	wander_direction = Vector2(cos(random_angle), sin(random_angle))
	wander_timer = randf_range(1.0, 3.0)

func perform_attack() -> void:
	if not can_attack:
		return
		
	can_attack = false
	print("Enemy attacks!")
	
	# Add attack animation or effects here
	# Example: $AnimatedSprite2D.play("attack")
	
	# Check if player is still in range
	if player != null and global_position.distance_to(player.global_position) <= ATTACK_RANGE:
		if player.has_method("take_damage"):
			player.take_damage(1)
	
	# Start attack cooldown
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true

func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	health -= amount
	print("Enemy took damage! Health: ", health)
	
	# Visual feedback for taking damage
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	print("Enemy died!")
	
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Optional: Add death animation
	# Example: $AnimatedSprite2D.play("death")
	
	# Wait for death animation
	await get_tree().create_timer(0.5).timeout
	
	# Remove enemy
	queue_free() 
