extends Node

class NetworkPlayer extends Spatial:
	var id

	static func gen_name(my_id):
		return "NetworkPlayer-" + str(my_id)

	func _init(_id):
		id = _id
		set_name(NetworkPlayer.gen_name(id))

	func is_local():
		return id == NetworkManager.id

var player_prefab = preload("res://player/Player.tscn")
var weapon_pickup = preload("res://world/WeaponPickup.tscn")

var players_to_spawn = []

export(NodePath) var spawn_points_node
export(float) var flight_factor = 3.0
onready var spawn_points: Array = get_node(spawn_points_node).get_children()

func add_player(id):
	var player = NetworkPlayer.new(id)
	player.set_network_master(id)
	add_child(player)

func _process(_delta):
	if players_to_spawn.size() > 0:
		var ply = players_to_spawn.pop_front()
		spawn(ply)

func get_player_instances():
	var instances = []
	for np in get_children():
		var instance = np.get_node_or_null("Player")
		if instance:
			instances.append(instance)
	return instances

func spawn(id):
	var network_player = get_node(NetworkPlayer.gen_name(id))
	assert(!network_player.get_node_or_null("Player"))
	var spawn = get_free_spawn()
	var player_inst = player_prefab.instance()
	player_inst.name = "Player"
	player_inst.set_network_master(id)
	player_inst.player_no = id
	if network_player.is_local():
		player_inst.local = true
		player_inst.camera_node = $"../PlayerScreen/Viewport/Camera"
		player_inst.screen = $"../PlayerScreen"
	player_inst.player_manager = self
	network_player.add_child(player_inst)
	player_inst.global_transform.origin = spawn.global_transform.origin
	player_inst.rotation.y = PI + spawn.rotation.y
	
remotesync func slay(player, dmg_info):
	var network_player = player.get_parent()
	## Ragdoll the character model
	var character_model = player.get_node("CharacterModel")
	player.remove_child(character_model)
	network_player.add_child(character_model)
	character_model.transform = player.global_transform
	character_model.rotate_y(PI)
	character_model.remove_from_group("thirdperson")
	Util.set_person_mask(character_model, "both", player.thirdperson_mask, player.firstperson_mask)
	character_model.connect("cleanup", self, "cleanup_ragdoll", [character_model, network_player.id])
	character_model.ragdoll(dmg_info["normal"] * -dmg_info["dmg"] * flight_factor)
	## Drop weapons as a pickup, with decay
	var weapon_pickup_inst = weapon_pickup.instance()
	weapon_pickup_inst.temporary = true
	weapon_pickup_inst.weaponid = player.weapon_controller.curr_id
	weapon_pickup_inst.model = player.weapon_controller.weapons[weapon_pickup_inst.weaponid]
	get_tree().get_root().add_child(weapon_pickup_inst)
	weapon_pickup_inst.transform.origin = player.global_transform.origin
	## Get rid of the player
	network_player.remove_child(player)
	player.queue_free()
	
func get_free_spawn():
	var offset = randi() % spawn_points.size()
	for i in range(spawn_points.size()):
		var p = (i + offset) % spawn_points.size()
		if spawn_points[p].can_spawn():
			return spawn_points[p]
	assert(false, "Could not find a safe spawn!")

func cleanup_ragdoll(ragdoll, id):
	ragdoll.queue_free()
	add_to_spawnlist(id)

func add_to_spawnlist(id):
	players_to_spawn.append(id)
