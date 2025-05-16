extends MultiplayerSynchronizer

@onready var player = $".."

@export var input_direction_x = 0
@export var input_direction_y = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
	
	input_direction_x = Input.get_axis("move_left", "move_right")
	input_direction_y = Input.get_axis("move_up", "move_down")

func _physics_process(delta):
	input_direction_x = Input.get_axis("move_left", "move_right")
	input_direction_y = Input.get_axis("move_up", "move_down")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("jump"):
		jump.rpc()

@rpc("call_local")
func jump():
	if multiplayer.is_server():
		player.do_jump = true
