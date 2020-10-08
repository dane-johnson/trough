extends Control

onready var label = $Label

var player_manager
var player_body

func _ready():
	player_manager = Util.first_in_tree(get_tree(), "PlayerManager")

func _process(_delta):
	if player_manager:
		player_body = player_manager.players[0]

	label.text = "DEBUG PANEL:\n"
	
	if not player_manager:
		label.text += "PlayerManager not found"
	else:
		if not player_body:
			label.text += "Found PlayerManager but no player"
		else:
			label.text += "Grounded " + str(player_body.is_on_floor()) + "\n"
			label.text += "Velocity: " + str(player_body.move_controller.velocity) + "\n"
			label.text += "Speed: " + str(player_body.move_controller.velocity.length()) + "\n"			
			label.text += "Last slide: " + str(player_body.move_controller.last_slide) + "\n"
