extends Control

onready var host_button = $Buttons/HostButton
onready var ip_field = $Buttons/IP
onready var join_button = $Buttons/JoinButton


var world = preload("res://World.tscn")

func _ready():
	host_button.connect("pressed", self, "start_game")
	join_button.connect("pressed", self, "join_game")
	
func start_game():
	var world_inst = world.instance()
	NetworkManager.player_manager = world_inst.get_node("PlayerManager")
	get_tree().get_root().add_child(world_inst)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	NetworkManager.host_game()
	hide()

func join_game():
	var world_inst = world.instance()
	NetworkManager.player_manager = world_inst.get_node("PlayerManager")
	get_tree().get_root().add_child(world_inst)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var ip_addr = ip_field.text
	if ip_addr == "":
		ip_addr = "localhost"
	NetworkManager.join_game(ip_addr)
	hide()
