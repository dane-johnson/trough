extends Control

var player = preload("res://player/Player.tscn")
var player_screen = preload("res://screen/PlayerScreen.tscn")
var screens = []

export(int) var num_players = 1

signal screens_created

func resize_screens():
	var width = rect_size.x
	var height = rect_size.y
	if (num_players) > 1:
		width /= 2
	if (num_players) > 2:
		height /= 2
	for i in range(num_players):
		screens[i].set_size(Vector2(width, height))
		screens[i].set_position(Vector2(width * (i % 2), height * (i / 2)))

func _ready():
	for i in range(num_players):
		var screen_inst = player_screen.instance()
		add_child(screen_inst)
		screens.append(screen_inst)
	resize_screens()
	emit_signal("screens_created", screens)
	get_tree().connect("screen_resized", self, "resize_screens")
