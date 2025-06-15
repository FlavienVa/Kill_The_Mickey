extends Area2D
class_name InteractionArea

@export var action_name: String = "interact"
var interact: Callable = func(): pass
var current_player: Node2D  
@onready var label = $Label
const base_text_player1 = "[E] to "
const base_text_player2 = "[SHIFT] to "

func _ready() -> void:
	label.hide()

func _on_body_entered(body):
	if body.is_in_group("player"):

		if PlayerManager.get_player_by_name("Player1") == body : 
			label.text = base_text_player1 + action_name
			if (action_name == "hide" or action_name == "enter") and body.is_shy() or action_name == "operate" and body.is_smart() or action_name == "pick" :
				label.show()
		elif PlayerManager.get_player_by_name("Player2") == body : 
			label.text = base_text_player2 + action_name
			if (action_name == "hide" or action_name == "enter") and body.is_shy() or action_name == "operate" and body.is_smart() or action_name == "pick":
				label.show()
		InteractionManager.register_area(self, body)
		current_player = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		InteractionManager.unregister_area(self, body)
		current_player = null
		label.hide()
