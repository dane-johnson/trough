extends Node

enum {HOST, CLIENT}

const PORT = 8008
const MAX_PLAYERS = 16

var player_manager
var network_mode
var peer
var id
var connections = 0

func _ready():
	get_tree().connect("connected_to_server", self, "on_connect")
	get_tree().connect("connection_failed", self, "on_server_dropped")
	get_tree().connect("network_peer_connected", self, "on_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "on_peer_dropped")
	get_tree().connect("server_disconnected", self, "on_server_dropped")


func host_game():
	network_mode = HOST
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT, 16)
	get_tree().network_peer = peer
	id = peer.get_unique_id()
	on_connect()

func join_game(ip):
	network_mode = CLIENT
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, PORT)
	get_tree().network_peer = peer
	id = peer.get_unique_id()

func on_connect():
	player_manager.add_player(id)
	player_manager.add_to_spawnlist(id)
	
func on_peer_connected(peer_id):
	player_manager.add_player(peer_id)
	player_manager.add_to_spawnlist(peer_id)

func on_peer_dropped(peer_id):
	player_manager.remove_player(peer_id)

func on_server_dropped():
	get_tree().quit()
