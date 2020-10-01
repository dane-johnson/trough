extends Control

var world = preload("res://World.tscn")
var players = 1

func _ready():
	$SpinBox.connect("value_changed", self, "change_players")
	$Button.connect("pressed", self, "start_game")
	
func change_players(num_players: float):
	players = int(num_players)
	
func start_game():
	var world_inst = world.instance()
	world_inst.get_node("PlayerManager").num_players = players
	world_inst.get_node("Splitscreen").num_players = players
	get_tree().get_root().add_child(world_inst)
	queue_free()
