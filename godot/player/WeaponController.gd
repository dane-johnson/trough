extends Node

var player
var third_person_weapon: Gun
var first_person_weapon: Gun
var fire_position: Spatial

var impact = preload("res://effects/impact.tscn")

func init(_player):
	player = _player
	first_person_weapon = player.get_node("./CameraRemote/WeaponSocket").get_child(0)
	third_person_weapon = player.get_node("./CharacterModel/Armature/Skeleton/Hand/WeaponSocket").get_child(0)
	fire_position = player.get_node("./CameraRemote")
	first_person_weapon.connect("attack", self, "do_raytrace_attack")
	
func _process(delta):
	# Auto aim
	var targets = player.get_valid_targets()
	var forward = -fire_position.global_transform.basis.z
	var closest
	var closest_angle = PI
	for tgt in targets:
		var basis = fire_position.global_transform.looking_at(tgt.get_autoaim_tgt().global_transform.origin, Vector3.UP).basis
		var angle = forward.angle_to(-basis.z)
		if angle < closest_angle:
			closest_angle = angle
			closest = basis
	## Pull towards nearest angle
	if closest and closest_angle < PI/12:
		player.interpolate_aim(closest, delta)
	
func fire_weapons():
	if first_person_weapon:
		first_person_weapon.attack()
	if third_person_weapon:
		third_person_weapon.attack()
		
func do_raytrace_attack():
	var space_state = player.get_world().get_direct_space_state()
	var res = space_state.intersect_ray(fire_position.global_transform.origin, fire_position.global_transform.origin - fire_position.global_transform.basis.z * 1000, [player], 0x5, true, true)
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
			
func attack():
	fire_weapons()
