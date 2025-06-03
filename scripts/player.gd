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

@onready var _health_bar := get_node("HealthBar")

var health := 3
var max_health := 3
var is_dead := false

@export var printer_path: NodePath
@onready var _printer := get_node(printer_path)



var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0
const KNOCKBACK_DURATION := 0.2
const KNOCKBACK_FORCE := 600.0



var current_weapon: Node2D = null
var weapon_original_parent: Node = null
var weapon_original_position: Vector2 = Vector2.ZERO

var facing_direction := Vector2.RIGHT
var weapon_target_rotation: float = 0.0
var weapon_rotation_speed: float = 20.0  # Increase for faster transition


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
	print("Health bar found:", _health_bar)
	print("Printer found: ", _printer)

	# Store the initial position for respawning
	initial_position = position
	# Add the player to the "player" group
	# Load a random variant at startup OVERRIDE WHEN CHARACTER CREATION IS IMPLEMENTED
	randomize()
	set_sprite_variant(variant_keys[randi() % variant_keys.size()])
	_health_bar.max_value = max_health
	_health_bar.value = health
	
func _process(delta: float) -> void:
	if current_weapon:
		var diff = weapon_target_rotation - current_weapon.rotation_degrees
		current_weapon.rotation_degrees += diff * delta * weapon_rotation_speed

	
func set_sprite_variant(variant_name: String) -> void:
	if sprite_variants.has(variant_name):
		_animated_sprite.sprite_frames = sprite_variants[variant_name]
	else:
		push_error("Variant '%s' not found!" % variant_name)

func _physics_process(delta: float) -> void:
	# Movement
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()
	
	velocity = input_vector * SPEED

	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_velocity
	else:
		# Normal movement
		input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		input_vector = input_vector.normalized()
		velocity = input_vector * SPEED

	
	if input_vector.x > 0:
		$AnimatedSprite2D.flip_h = false
		facing_direction = Vector2.RIGHT
		if has_knife and current_weapon:
			current_weapon.scale.x = abs(current_weapon.scale.x)
			$WeaponSocket.position.x = abs($WeaponSocket.position.x)

			

	elif input_vector.x < 0:
		$AnimatedSprite2D.flip_h = true
		facing_direction = Vector2.LEFT
		if has_knife and current_weapon:
			current_weapon.scale.x = -abs(current_weapon.scale.x)
			$WeaponSocket.position.x = -abs($WeaponSocket.position.x)
			
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

	# Animate weapon forward during attack
	if current_weapon:
		weapon_target_rotation = 90.0 if not $AnimatedSprite2D.flip_h else -90.0

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
	#$AnimatedSprite2D.play("attack")
	
	
	# Wait for attack duration
	await get_tree().create_timer(0.2).timeout
		# Reset weapon to original position
	if current_weapon:
		weapon_target_rotation = 0.0

	is_attacking = false
	attack_hitbox.queue_free()
	
	# Wait for cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_attack_hit(body: Node2D) -> void:
	print("There is someone under your sword")
	if body.has_method("take_damage"):
		print(body)
		body.take_damage(ATTACK_DAMAGE, global_position)
	print("Hit enemy!")
		
func take_damage(amount: int, source_position: Vector2) -> void:
	if is_dead:
		return

	# Reduce health first
	health -= amount
	health = clamp(health, 0, max_health)

	update_health_bar()

	# Only apply knockback if we're not dead
	if health > 0:
		var knockback_direction = (position - source_position).normalized()
		apply_knockback(knockback_direction)

	_health_bar.value = health

	if health <= 0:
		is_dead = true
		mark_dead()


func apply_knockback(direction: Vector2) -> void:
	knockback_velocity = direction * KNOCKBACK_FORCE
	knockback_timer = KNOCKBACK_DURATION
	
func update_health_bar():
	var health_ratio = float(health) / max_health
	_health_bar.value = health

	# Calculate color: green at full, red at zero
	var red = 1.0 - health_ratio
	var green = health_ratio
	var color = Color(red, green, 0)

	_health_bar.add_theme_color_override("fill", color)

		
func mark_dead() -> void:
	
	if current_weapon and weapon_original_parent:
		
		$WeaponSocket.remove_child(current_weapon)
		weapon_original_parent.add_child(current_weapon)
		current_weapon.to_original()
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
	if (MultiplayerManager.fluidleft > 0) and not _printer.is_destroyed:
		respawn()
	else : 
		_game_over()


func respawn() -> void:
	if _printer:
		position = _printer.global_position
	else:
		position = initial_position  # fallback
	# Re-enable player movement and input
	set_physics_process(true)
	# Change the variant
	set_sprite_variant(variant_keys[randi() % variant_keys.size()])
	# Make the player visible again
	$AnimatedSprite2D.visible = true
	if current_weapon:
		current_weapon.visible = true
	
	# Reset health
	health = max_health
	_health_bar.value = health
	
	is_dead = false

	
	
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
	


func _on_foot_step_timer_timeout() -> void:
	if velocity.length() > 0:
		var random_index = randi() % footstep_sounds.size()
		$FootStepAudio.stream = footstep_sounds[random_index]
		$FootStepAudio.pitch_scale = randf_range(0.95, 1.05)
		_footstep_audio.play()
