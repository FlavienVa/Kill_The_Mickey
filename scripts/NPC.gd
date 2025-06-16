extends CharacterBody2D

@export var speed := 250

var direction := Vector2.RIGHT
var move_duration := 10.0
var move_timer := 0.0
var path_follow: PathFollow2D

@export var printer_path: NodePath
@onready var _printer := get_node(printer_path)

func _ready():
	move_timer = move_duration
	direction = Vector2.RIGHT  # Start moving right
	
	$Area2D.connect("body_entered", Callable(self, "_on_body_entered"))
	$Area2D.connect("body_exited", Callable(self, "_on_body_exited"))
	path_follow = $PathFollow2D  # or get_node("PathFollow2D") if needed

func _process(delta):
	if path_follow:
		path_follow.progress += speed * delta

func _physics_process(delta):
	move_timer -= delta

	if move_timer <= 0:
		direction = -direction
		move_timer = move_duration

	velocity = direction * speed
	move_and_slide()

	#Flip the sprite
	if direction.x != 0:
		$AnimatedSprite2D.flip_h = direction.x < 0

	var suspicion_shape = $SuspicionRadius/CollisionShape2D
	if suspicion_shape and suspicion_shape.shape:
		var offset = suspicion_shape.position
		offset.x = abs(offset.x) * sign(direction.x)
		suspicion_shape.position = offset


		
	# Play animation
	if velocity.length() > 0:
		if not $AnimatedSprite2D.is_playing() or $AnimatedSprite2D.animation != "run":
			$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("idle")

var players_in_radius := []

func _on_suspicion_radius_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		players_in_radius.append(body)
		check_suspicion()

func _on_suspicion_radius_body_exited(body: Node2D) -> void:
	if body in players_in_radius:
		players_in_radius.erase(body)
		check_suspicion()

func check_suspicion():
	if players_in_radius.size() > 1:
		# Trigger printer break
		_printer.die()
		
