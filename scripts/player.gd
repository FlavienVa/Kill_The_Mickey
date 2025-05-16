extends CharacterBody2D

const SPEED = 300.0

var has_knife := false
var attack_cooldown := 0.5
var can_attack := true

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
	can_attack = false
	print("Attacked with knife!")
	# You can spawn a slash, play animation, or detect enemies here
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
