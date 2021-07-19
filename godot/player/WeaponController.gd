extends Node

export var autoaim_cone = 15.0
export var autoaim = false

var player
var third_person_weapon: Gun
var first_person_weapon: Gun
var first_person_weapon_socket: Spatial
var third_person_weapon_socket: Spatial
var fire_position: Spatial
var curr_id = -1
var attacking = false

var impact = preload("res://effects/impact.tscn")

var weapons = [
	preload("res://weapons/Pistol.tscn"),
	preload("res://weapons/M1.tscn"),
	preload("res://weapons/Bar.tscn"),
	
]

func init(_player):
	player = _player
	first_person_weapon_socket = player.get_node("./CameraRemote/WeaponSocket")
	third_person_weapon_socket = player.get_node("./CharacterModel/Armature/Skeleton/Hand/WeaponSocket")
	fire_position = player.get_node("./CameraRemote")
	
	## Give them an M1
	change_weapon(0)
	
func _process(delta):
	if not player.local or not autoaim:
		return
	# Auto aim
	var targets = player.get_valid_targets()
	var forward = -fire_position.global_transform.basis.z
	var closest
	var closest_angle = PI
	for tgt in targets:
		var basis = fire_position.global_transform.looking_at(tgt.get_autoaim_tgt().global_transform.origin, Vector3.UP).basis
		var angle = forward.angle_to(-basis.z)
		if angle < closest_angle and can_see(tgt):
			closest_angle = angle
			closest = basis
	## Pull towards nearest angle
	if closest and closest_angle < deg2rad(autoaim_cone):
		player.interpolate_aim(closest, 1.0 - (closest_angle / deg2rad(autoaim_cone)), delta)
	
func fire_weapons():
	if first_person_weapon:
		first_person_weapon.attack()
	if third_person_weapon:
		third_person_weapon.attack()
		
		
func stop_weapons():
	if first_person_weapon:
		first_person_weapon.stop_attack()
	if third_person_weapon:
		third_person_weapon.stop_attack()
		
func can_see(tgt):
	var space_state = player.get_world().get_direct_space_state()
	var res = space_state.intersect_ray(fire_position.global_transform.origin, tgt.global_transform.origin, player.get_hitboxes(), 0x5, true, true)
	return res and res.collider == tgt

func do_raytrace_attack():
	var space_state = player.get_world().get_direct_space_state()
	var res = space_state.intersect_ray(fire_position.global_transform.origin, fire_position.global_transform.origin - fire_position.global_transform.basis.z * 1000, player.get_hitboxes(), 0x5, true, true)
	if res:
		var impact_inst = impact.instance()
		get_tree().get_root().add_child(impact_inst)
		impact_inst.global_transform.origin = res.position
		if res.collider.has_method("hurt"):
			impact_inst.emit(res.normal, true)
			var dmg_info = {"dmg": first_person_weapon.damage,
							"position": res.position,
							"normal": res.normal}
			res.collider.hurt(dmg_info)
		else:
			impact_inst.emit(res.normal, false)
			
func do_melee_attack():
	var bodies = player.get_node("MeleeDamage").get_overlapping_bodies()
	for body in bodies:
		if body == player:
			continue
		var dmg_info = {
			"dmg": 50,
			"position": player.global_transform.origin,
			"normal": body.global_transform.origin.direction_to(player.global_transform.origin)
		}
		body.hurt(dmg_info)

func attack():
	attacking = true
	fire_weapons()
	
func melee():
	if not attacking:
		player.set_anim_state_pistolwhip()
	$MeleeDamageTimer.start()

func stop_attack():
	attacking = false
	stop_weapons()
	
func change_weapon(weaponid):
	if weaponid == curr_id:
		return false
	curr_id = weaponid
	if first_person_weapon:
		first_person_weapon.queue_free()
	if third_person_weapon:
		third_person_weapon.queue_free()
	var weapon = weapons[weaponid]
	first_person_weapon = weapon.instance()
	Util.set_person_mask(first_person_weapon, "firstperson", player.thirdperson_mask, player.firstperson_mask)
	first_person_weapon_socket.add_child(first_person_weapon)
	first_person_weapon.connect("attack", self, "do_raytrace_attack")
	third_person_weapon = weapon.instance()
	Util.set_person_mask(third_person_weapon, "thirdperson", player.thirdperson_mask, player.firstperson_mask)
	third_person_weapon_socket.add_child(third_person_weapon)
	return true

func zoom():
	player.zoom_to(70 / first_person_weapon.zoom)

func unzoom():
	player.zoom_to(70)
