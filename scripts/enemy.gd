extends CharacterBody2D

var enemy_scene = preload("res://scenes/enemy.tscn")

const SPEED = 400.0
const DETECTION_RADIUS = 500.0
const ATTACK_RANGE = 50.0
const ATTACK_COOLDOWN = 1.5

var health := 3
var max_health := 3
var is_dead := false
var can_attack := true
var player = null
var direction := Vector2.ZERO
var spawn_position := Vector2.ZERO


var is_knocked_back := false
var knockback_timer := 0.0
var knockback_velocity := Vector2.ZERO


@onready var health_label = $HealthLabel


func _ready() -> void:
	add_to_group("enemy")
	spawn_position = global_position
	update_health_label()
	randomize()
	#pawn_enemies()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_knocked_back:
		velocity = knockback_velocity
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knocked_back = false
			velocity = Vector2.ZERO
	else:
		if player == null:
			find_player()

		if player != null:
			handle_player_detection()

	move_and_slide()

#func spawn_enemies():
#	for i in range(10):
#		var enemy = enemy_scene.instantiate()
#		var random_x = randi_range(100, 800)
#		var random_y = randi_range(100, 600)
#		enemy.global_position = Vector2(random_x, random_y)
#		add_child(enemy)

func find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func handle_player_detection() -> void:
	if player == null:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player <= DETECTION_RADIUS:
		direction = (player.global_position - global_position).normalized()
		velocity = direction * SPEED

		if distance_to_player <= ATTACK_RANGE and can_attack:
			#perform_attack()
			print("close")
	else:
		velocity = Vector2.ZERO

func perform_attack() -> void:
	if not can_attack:
		return

	can_attack = false
	print("Enemy attacks!")

	if player != null and global_position.distance_to(player.global_position) <= ATTACK_RANGE:
		if player.has_method("take_damage"):
			player.take_damage(1)

	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount
	print("Enemy took damage! Health remaining: ", health)

	update_health_label()

	if player != null:
		var knockback_direction = (global_position - player.global_position).normalized()
		knockback_velocity = knockback_direction * 700  # Testa olika styrkor
		knockback_timer = 0.3  # Hur länge knockbacken pågår
		is_knocked_back = true

	# Visuell feedback
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

	if health <= 0:
		die()


func update_health_label() -> void:
	if health_label:
		health_label.text = str(health) + "/" + str(max_health)

func die() -> void:
	is_dead = true
	print("Enemy died!")
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Valfritt: spela dödsanimation, ljud osv
	await get_tree().create_timer(0.5).timeout
	
	# Starta respawn
	respawn_enemy()
	
	queue_free()

func respawn_enemy():
	var new_enemy = enemy_scene.instantiate()
	new_enemy.global_position = spawn_position
	
	get_tree().current_scene.add_child(new_enemy)  # Lägg till i nuvarande nivå
