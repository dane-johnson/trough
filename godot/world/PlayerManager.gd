extends Node

var player = preload("res://player/Player.tscn")
var weapon_pickup = preload("res://world/WeaponPickup.tscn")

var players = []
var screens = []
var players_to_spawn = []

export(int) var num_players
export(NodePath) var spawn_points_node
export(float) var flight_factor = 3.0
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
	player_inst.rotation.y = PI + spawn.rotation.y
	players[player_no - 1] = player_inst
	
func slay(player_no: int, dmg_info):
	var player_inst = players[player_no - 1]
	## Ragdoll the character model
	var character_model = player_inst.get_node("CharacterModel")
	player_inst.remove_child(character_model)
	get_tree().get_root().add_child(character_model)
	character_model.transform = player_inst.global_transform
	character_model.rotate_y(PI)
	Util.set_person_mask(character_model, "both", player_inst.thirdperson_mask, player_inst.firstperson_mask)
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
	## Respawn the player
	players_to_spawn.append(player_no)
	
func get_free_spawn():
	var offset = randi() % spawn_points.size()
	for i in range(spawn_points.size()):
		var p = (i + offset) % spawn_points.size()
		if spawn_points[p].can_spawn():
			return spawn_points[p]
	assert(false, "Could not find a safe spawn!")

func spawn_all():
	players_to_spawn = range(1, num_players + 1)
