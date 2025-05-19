extends CharacterBody2D

const SPEED = 1300.0
const ATTACK_COOLDOWN = 0.5
const ATTACK_DAMAGE = 1
const ATTACK_RANGE = 2000.0
var has_knife := false

@onready var animated_sprite = $AnimatedSprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var direction_x = 1
var direction_y = 0
var _is_on_floor = true
var alive = true
var health := 3
var max_health := 3
var can_attack := true
var attack_direction := Vector2.RIGHT
var is_attacking := false

@export var player_id := 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

func _ready():
	if multiplayer.get_unique_id() == player_id:
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false
	
	# Add player to the "player" group for attack detection
	add_to_group("player")

func _apply_movement_from_input(delta):
	# Get the input direction: -1, 0, 1
	direction_x = %InputSynchronizer.input_direction_x
	direction_y = %InputSynchronizer.input_direction_y
	
	# Apply movement
	if direction_x:
		velocity.x = direction_x * SPEED
		velocity.y = 0  # Reset vertical velocity when moving horizontally
		attack_direction = Vector2(direction_x, 0)
	elif direction_y:
		velocity.y = direction_y * SPEED
		velocity.x = 0  # Reset horizontal velocity when moving vertically
		attack_direction = Vector2(0, direction_y)
	else:
		# Reset both velocities when no input
		velocity.x = 0
		velocity.y = 0

	move_and_slide()
	
	# Handle attack input
	if Input.is_action_just_pressed("attack") and can_attack:
		perform_attack.rpc()

@rpc("any_peer", "call_local")
func perform_attack():
	if not can_attack:
		return
		
	can_attack = false
	is_attacking = true
	print("Player attacks!")
	
	# Create attack hitbox
	var attack_hitbox = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ATTACK_RANGE, 50)
	collision_shape.shape = shape
	attack_hitbox.add_child(collision_shape)
	
	# Position the hitbox in front of the player
	attack_hitbox.position = attack_direction * (ATTACK_RANGE / 2)
	add_child(attack_hitbox)
	
	# Connect to detect hits
	attack_hitbox.body_entered.connect(_on_attack_hit)
	
	# Wait for attack duration
	await get_tree().create_timer(0.2).timeout
	is_attacking = false
	attack_hitbox.queue_free()
	
	# Wait for cooldown
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true

func _on_attack_hit(body: Node2D) -> void:
	if body.is_in_group("player") and body != self:
		# Handle player hit
		if body.has_method("take_damage"):
			body.take_damage.rpc(ATTACK_DAMAGE)
		print("Hit player!")

@rpc("any_peer", "call_local")
func take_damage(amount: int) -> void:
	if not alive:
		return
		
	health -= amount
	print("Player took damage! Health remaining: ", health)
	
	# Visual feedback for taking damage
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if health <= 0:
		mark_dead()

func _physics_process(delta):
	if multiplayer.is_server():
		if not alive && is_on_floor():
			_set_alive()
		
		_is_on_floor = is_on_floor()
		_apply_movement_from_input(delta)

func mark_dead():
	print("Mark player dead!")
	alive = false
	health = max_health  # Reset health for respawn
	$CollisionShape2D.set_deferred("disabled", true)
	$RespawnTimer.start()

func _respawn():
	print("Respawned!")
	position = MultiplayerManager.respawn_point
	$CollisionShape2D.set_deferred("disabled", false)

func _set_alive():
	print("alive again!")
	alive = true
	Engine.time_scale = 1.0

func _on_respawn_timer_timeout() -> void:
	_respawn()
