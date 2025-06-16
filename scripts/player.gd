extends CharacterBody2D

@export var ui: Node = null

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
var current_weapon_name := ""
var weapon_original_parent: Node = null
var weapon_original_position: Vector2 = Vector2.ZERO

var facing_direction := Vector2.RIGHT
var weapon_target_rotation: float = 0.0
var weapon_rotation_speed: float = 20.0  # Increase for faster transition

@onready var _health_bar := $"HealthBar"

var health := 3
var max_health := 3
var is_dead := false
var deaths = 0
var fluid_left = 4

var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

var is_immobilized := false

@export var printer_path: NodePath
@onready var _printer := get_node(printer_path)


@onready var _animated_sprite := $AnimatedSprite2D

# Preload or load variant resources
var sprite_variants = {
	"happy": preload("res://player/variants/happy.tres"),
	"angry": preload("res://player/variants/angry.tres"),
	"smart": preload("res://player/variants/smart.tres"),
	"shy": preload("res://player/variants/shy.tres") 
}
var variant_keys = sprite_variants.keys()
var current_variant = ""

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
	if name == "Player1":
		PlayerManager.register_player(self, 1)
	else:
		PlayerManager.register_player(self, 2)


	
	# Load a random variant at startup OVERRIDE WHEN CHARACTER CREATION IS IMPLEMENTED
	randomize()
	set_sprite_variant(variant_keys[randi() % variant_keys.size()])
	
	
func _process(delta: float) -> void:
	if current_weapon:
		var diff = weapon_target_rotation - current_weapon.rotation_degrees
		current_weapon.rotation_degrees += diff * delta * weapon_rotation_speed
		
	# Placing traps
	if player_id == 1 and Input.is_action_just_pressed("p1_placetrap") and can_place_trap and current_variant == "happy" and traps_remaining > 0:		
		place_trap()
	elif player_id == 2 and Input.is_action_just_pressed("p2_placetrap") and can_place_trap and current_variant == "happy" and traps_remaining > 0:		
		place_trap()
		
	# Initialize UI
	if ui:
		ui.update_fluid(_printer.ink)
		ui.update_deaths(deaths)
		if current_variant == "happy":
			ui.show_variant_label("HappyLabel", player_id)
		else:
			ui.remove_label("HappyLabel")
		if _printer.is_dead:
			ui.show_printer_label()
		if self.fluid_left == 0 or (_printer.is_dead and is_dead):
			ui.show_winner_label(player_id)

		
	

	
func set_sprite_variant(variant_name: String) -> void:
	if sprite_variants.has(variant_name):
		_animated_sprite.sprite_frames = sprite_variants[variant_name]
		current_variant = variant_name
	else:
		push_error("Variant '%s' not found!" % variant_name)

# Method for doors
func is_smart():
	if current_variant == "smart":
		return true
	else:
		return false
# Method for hiding
func is_shy():
	if current_variant == "shy":
		return true
	else:
		return false
# Method for breaking doors
func is_angry():
	if current_variant == 'angry':
		return true
	else:
		return false

func _physics_process(delta: float) -> void:
	# Movement with player-specific input
	var input_vector := Vector2.ZERO
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_velocity
	# Triggered a trap
	elif is_immobilized:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# Normal movement
	else:
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

	# Attack logic with player-specific input
	var attack_input = ""
	if player_id == 1:
		attack_input = "p1_attack"
	elif player_id == 2:
		attack_input = "p2_attack"
	
	if has_knife or is_angry() and Input.is_action_just_pressed(attack_input) and can_attack:
		perform_attack()

func pickup_weapon(weapon: Node2D) -> void:
	var drop_position = weapon.global_position
	var drop_parent = weapon.get_parent()

	# If already holding a weapon, drop it where the new weapon was
	if current_weapon and current_weapon != weapon:
		drop_current_weapon_at(drop_parent, drop_position)

	has_knife = true
	current_weapon = weapon
	current_weapon_name = weapon.name
	weapon_original_parent = weapon.get_parent()
	weapon_original_position = weapon.position

	if weapon.get_parent():
		weapon.get_parent().remove_child(weapon)

	$WeaponSocket.add_child(weapon)
	weapon.position = Vector2.ZERO
	weapon.visible = true
	weapon.scale = Vector2.ONE
	weapon.z_index = 10
	weapon.modulate = Color(1, 1, 1, 1)

func drop_current_weapon_at(parent: Node, position: Vector2):
	if current_weapon:
		$WeaponSocket.remove_child(current_weapon)
		parent.add_child(current_weapon)
		current_weapon.global_position = position
		current_weapon.to_original()
		current_weapon = null

	
func perform_attack():
	if not can_attack or not has_knife and not is_angry():
		return
		
	can_attack = false
	is_attacking = true

	if is_angry():
		$AnimatedSprite2D.play("hit")
		
	# Animate weapon forward during attack
	if current_weapon:
		weapon_target_rotation = 90.0 if not $AnimatedSprite2D.flip_h else -90.0

			

	# Animate weapon rotation (swinging down)
	if current_weapon:
		current_weapon.rotation_degrees = -45 if not $AnimatedSprite2D.flip_h else 45

	print("ATTACK")
	
	$WeaponSwingAudio.play()
	
	# Store current attack direction based on movement or last direction
	attack_direction = facing_direction
	
	
	# Create attack hitbox
	var attack_hitbox = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	if current_weapon_name == "gun":
		shape.size = Vector2(1000, 50)
	else:
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
	print("Player %d hit something with sword" % player_id)
	if body.is_in_group("enemy"):
		# Handle enemy hit
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)
		print("Hit enemy!")
	if body.is_in_group("doors"):
		if body.has_method("take_damage"):
			body.take_damage()
	if body.is_in_group("player") and body != self:
		body.take_damage(ATTACK_DAMAGE, global_position)
	
func take_damage(amount: int, source_position: Vector2) -> void:
	if is_dead:
		return
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	# Reduce health first
	health -= amount
	health = clamp(health, 0, max_health)

	update_health_bar()
	# Only apply knockback if we're not dead
	if health > 0:
		var knockback_direction = (position - source_position).normalized()
		knockback_velocity = knockback_direction * 1000
		knockback_timer = 0.3

	_health_bar.value = health
	
	$DamageTakenAudio.play()

	if health <= 0:
		is_dead = true
		mark_dead()


	
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
	$AnimatedSprite2D.visible = false
	$HealthBar.visible = false

	
	# Wait a short moment before respawning
	await get_tree().create_timer(1.0).timeout
	deaths += 1
	fluid_left = _printer.use_ink()
	ui.update_fluid(fluid_left)
	ui.update_deaths(deaths)
	
	if fluid_left > 0 and not _printer.is_dead:
		respawn()
	else:
		self.is_dead = true
		_game_over()

func respawn() -> void:
	# Reset position to initial spawn point
	position = initial_position
	# Re-enable player movement and input
	set_physics_process(true)
	# Change the variant
	set_sprite_variant(variant_keys[randi() % variant_keys.size()])
	# Restock the traps
	traps_remaining = 5
	# Make the player visible again
	$AnimatedSprite2D.visible = true
	if current_weapon:
		current_weapon.visible = true
	# Reset health
	health = max_health
	_health_bar.value = health
	_health_bar.visible = true
	is_dead = false

	
	
func _game_over() -> void:
	# Disable player movement and input
	set_physics_process(false)
	$AnimatedSprite2D.visible = false
	
	# Show game over message for this player
	print("Player %d GAME OVER - Deaths: %d" % [player_id, deaths])

	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
	# You might want to handle this differently for split screen
	# Maybe show a game over overlay for just this player's viewport
		# Check if both players are dead before restarting
	# var all_players = get_tree().get_nodes_in_group("player")
	# var living_players = 0

	# for player in all_players:
	# 	if player.fluid_left > 0 and player != self:
	# 		living_players += 1
			
	# 		# Show "You Winx" to the surviving player
	# 		var win_label = player.get_node_or_null("YouWinLabel")
	# 		if win_label:
	# 			win_label.text = "The other player has died!\nYou won!"
	# 			win_label.visible = true

	# # Show "You Lost" on the dying player
	# var lose_label = get_node_or_null("YouWinLabel")  # assuming you're in the dying player
	# if lose_label:
	# 	lose_label.text = "You died!\nYou lost!"
	# 	lose_label.visible = true



func _on_foot_step_timer_timeout() -> void:
	if velocity.length() > 0:
		var random_index = randi() % footstep_sounds.size()
		$FootStepAudio.stream = footstep_sounds[random_index]
		$FootStepAudio.pitch_scale = randf_range(0.95, 1.05)
		_footstep_audio.play()
		


func _unhandled_input(event):
	if event.is_action_pressed("player1_interact" if name == "Player1" else "player2_interact"):
		InteractionManager.handle_player_interaction(self)

#Trap logic
@export var trap_scene: PackedScene = preload("res://scenes/trap.tscn")
var trap_cooldown := 4.0
var can_place_trap := true
var traps_remaining := 5

func place_trap():
	var trap = trap_scene.instantiate()
	trap.global_position = self.position
	trap.trap_owner = self
	get_parent().add_child(trap)
	traps_remaining -= 1
	ui.update_traps(traps_remaining, player_id)
	can_place_trap = false
	await get_tree().create_timer(trap_cooldown).timeout
	can_place_trap = true

func immobilize(duration):
	if is_immobilized:
		return  # Already immobilized

	is_immobilized = true
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 0.5)  # Optional: visual feedback
	await get_tree().create_timer(duration).timeout
	is_immobilized = false
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)  # Restore normal visuals
	


# Replace with function body.
