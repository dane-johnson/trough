extends Node

var player = preload("res://player/Player.tscn")

var players = []
var screens = []
var players_to_spawn = []

export(int) var num_players
export(NodePath) var spawn_points_node
onready var spawn_points: Array = get_node(spawn_points_node).get_children()

func _ready():
	players.resize(num_players)

func _process(delta):
	if players_to_spawn.size() > 0:
		var ply = players_to_spawn.pop_front()
		spawn(ply)

func start_game(_screens):
	screens = _screens
	spawn_all()

func spawn(player_no: int):
	var spawn = get_free_spawn()
	var player_inst = player.instance()
	player_inst.player_no = player_no
	player_inst.camera_node = screens[player_no - 1].get_node("Viewport/Camera")
	player_inst.player_manager = self
	player_inst.screen = screens[player_no - 1]
	get_tree().get_root().add_child(player_inst)
	player_inst.global_transform.origin = spawn.global_transform.origin
	players[player_no - 1] = player_inst
	
func get_free_spawn():
	var offset = randi() % spawn_points.size()
	for i in range(spawn_points.size()):
		var p = (i + offset) % spawn_points.size()
		if spawn_points[p].can_spawn():
			return spawn_points[p]
	assert(false, "Could not find a safe spawn!")

func spawn_all():
	players_to_spawn = range(1, num_players + 1)
