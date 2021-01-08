extends Node

enum {HOST, CLIENT}

const PORT = 8008
const MAX_PLAYERS = 16
const HOST_ID = 1

var player_manager
var local_player
var network_mode
var peer
var id

func _ready():
	get_tree().connect("connected_to_server", self, "on_connect")
	get_tree().connect("network_peer_connected", self, "on_peer_connected")

func host_game():
	network_mode = HOST
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT, 16)
	get_tree().network_peer = peer
	id = HOST_ID
	player_manager.add_local_player(id)
	player_manager.start_game()

func join_game(ip):
	network_mode = CLIENT
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, PORT)
	get_tree().network_peer = peer

func on_connect():
	id = get_tree().get_network_unique_id()
	player_manager.add_local_player(id)
	player_manager.join_in_progress(id)
	
func on_peer_connected(id):
	player_manager.add_remote_player(id)
