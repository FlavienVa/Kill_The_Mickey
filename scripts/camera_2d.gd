# camera_follow.gd
extends Camera2D

var target: Node2D = null
@export var follow_speed: float = 5.0


func _ready():
	# Disable drag margins for better split screen experience
	drag_horizontal_enabled = false
	drag_vertical_enabled = false

func _physics_process(delta):
	if target and is_instance_valid(target):
		# Smooth camera following
		global_position = global_position.lerp(target.global_position + offset, follow_speed * delta)
		# Or for instant following: global_position = target.global_position + offset
