extends CharacterBody2D

const SPEED = 1300.0

@onready var animated_sprite = $AnimatedSprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var direction_x = 1
var direction_y = 0
var do_jump = false
var _is_on_floor = true
var alive = true

@export var player_id := 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

func _ready():
	if multiplayer.get_unique_id() == player_id:
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false


func _apply_movement_from_input(delta):
	# Get the input direction: -1, 0, 1
	direction_x = %InputSynchronizer.input_direction_x
	direction_y = %InputSynchronizer.input_direction_y
	
	# Apply movement
	if direction_x:
		velocity.x = direction_x * SPEED
		velocity.y = 0  # Reset vertical velocity when moving horizontally
	elif direction_y:
		velocity.y = direction_y * SPEED
		velocity.x = 0  # Reset horizontal velocity when moving vertically
	else:
		# Reset both velocities when no input
		velocity.x = 0
		velocity.y = 0

	move_and_slide()

func _physics_process(delta):
	if multiplayer.is_server():
		if not alive && is_on_floor():
			_set_alive()
		
		_is_on_floor = is_on_floor()
		_apply_movement_from_input(delta)
		

func mark_dead():
	print("Mark player dead!")
	alive = false
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
	pass # Replace with function body.
