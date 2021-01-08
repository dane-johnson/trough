extends Node

class NetworkPlayer:
	var id
	var instance
	var local = false

	func _init(my_id):
		id = my_id

var player_prefab = preload("res://player/Player.tscn")
var weapon_pickup = preload("res://world/WeaponPickup.tscn")

var players = {}
var players_to_spawn = []

export(NodePath) var spawn_points_node
export(float) var flight_factor = 3.0
onready var spawn_points: Array = get_node(spawn_points_node).get_children()

func add_local_player(id):
	var player = NetworkPlayer.new(id)
	player.local = true
	players[id] = player

remote func add_remote_player(id):
	if id == NetworkManager.id:
		return
	var player = NetworkPlayer.new(id)
	player.local = false
	players[id] = player
	add_to_spawnlist(id)

func _process(delta):
	if players_to_spawn.size() > 0:
		var ply = players_to_spawn.pop_front()
		spawn(ply)

func get_player_instances():
	var instances = []
	for np in players.values():
		instances.append(np.instance)
	return instances

remote func sync_players():
	var new_connection = get_tree().get_rpc_sender_id()
	for id in players:
		rpc_id(new_connection, "add_remote_player", id)

func start_game():
	spawn_all()

func join_in_progress(id):
	rpc_id(NetworkManager.HOST_ID, "sync_players")
	rpc("add_to_spawnlist", id)

func spawn(id):
	var spawn = get_free_spawn()
	var player_inst = player_prefab.instance()
	player_inst.set_network_master(id)
	player_inst.player_no = id
	if players[id].local:
		player_inst.local = true
		player_inst.camera_node = $"../PlayerScreen/Viewport/Camera"
		player_inst.screen = $"../PlayerScreen"
	player_inst.player_manager = self
	get_tree().get_root().add_child(player_inst)
	player_inst.global_transform.origin = spawn.global_transform.origin
	player_inst.rotation.y = PI + spawn.rotation.y
	players[id].instance = player_inst
	
remotesync func slay(id: int, dmg_info):
	var player_inst = players[id].instance
	## Ragdoll the character model
	var character_model = player_inst.get_node("CharacterModel")
	player_inst.remove_child(character_model)
	get_tree().get_root().add_child(character_model)
	character_model.transform = player_inst.global_transform
	character_model.rotate_y(PI)
	character_model.remove_from_group("thirdperson")
	Util.set_person_mask(character_model, "both", player_inst.thirdperson_mask, player_inst.firstperson_mask)
	character_model.connect("cleanup", self, "cleanup_ragdoll", [character_model, id])
	character_model.ragdoll(dmg_info["normal"] * -dmg_info["dmg"] * flight_factor)
	## Drop weapons as a pickup, with decay
	var weapon_pickup_inst = weapon_pickup.instance()
	weapon_pickup_inst.temporary = true
	weapon_pickup_inst.weaponid = player_inst.weapon_controller.curr_id
	weapon_pickup_inst.model = player_inst.weapon_controller.weapons[weapon_pickup_inst.weaponid]
	get_tree().get_root().add_child(weapon_pickup_inst)
	weapon_pickup_inst.transform.origin = player_inst.global_transform.origin
	## Get rid of the player
	get_tree().get_root().remove_child(player_inst)
	player_inst.queue_free()
	
func get_free_spawn():
	var offset = randi() % spawn_points.size()
	for i in range(spawn_points.size()):
		var p = (i + offset) % spawn_points.size()
		if spawn_points[p].can_spawn():
			return spawn_points[p]
	assert(false, "Could not find a safe spawn!")

func spawn_all():
	players_to_spawn = players.keys()

func cleanup_ragdoll(ragdoll, id):
	ragdoll.queue_free()
	rpc("add_to_spawnlist", id)

remotesync func add_to_spawnlist(id):
	players_to_spawn.append(id)
