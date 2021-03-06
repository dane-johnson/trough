extends KinematicBody

export(int) var player_no = 1
export(float) var sensitivity = 2.5
export(float) var joy_dampen = 0.1
export(float) var autoaim_help = 8.0

onready var move_controller = $MoveController
onready var weapon_controller = $WeaponController
onready var health_controller = $HealthController
onready var camera = $CameraRemote
onready var thirdpersonanim = $CharacterModel/AnimationPlayer
onready var firstpersonanim = $AnimationPlayer

var firstperson_mask
var thirdperson_mask

## These values are supplied by the player manager
var player_manager
var camera_node
var screen

enum {ANIM_IDLE, ANIM_RUNNING, ANIM_PISTOLWHIP}
var anim_state = ANIM_IDLE

func _ready():
	var camera_path = get_path_to(camera_node)
	camera.set_remote_node("../" + camera_path)
	firstperson_mask = 0x1 << (player_no)
	thirdperson_mask = 0x1e & ~(firstperson_mask)
	Util.set_person_mask(self, "both", thirdperson_mask, firstperson_mask)
	get_node(camera_path).set_cull_mask(0x1 | firstperson_mask)
	
	move_controller.init(self)
	weapon_controller.init(self)
	health_controller.init(self)
	
	for hitbox in get_hitboxes():
		hitbox.connect("hurt", self, "hurt")
		
	thirdpersonanim.connect("animation_finished", self, "finish_anim")
	
	var skin_opts = $CharacterModel.skins.keys()
	$CharacterModel.skin = skin_opts[(player_no - 1) % skin_opts.size()]
	$CharacterModel.update_skin()

func _process(_delta):
	# Handle inputs
	var move_vec = Vector3.ZERO
	move_vec.x = Input.get_joy_axis(player_no - 1, JOY_ANALOG_LX)
	move_vec.z = Input.get_joy_axis(player_no - 1, JOY_ANALOG_LY)
	move_vec = dampen_joy_input(move_vec)
	move_controller.move_vec = move_vec

	var turn_vec = Vector3.ZERO
	turn_vec.x = Input.get_joy_axis(player_no - 1, JOY_ANALOG_RX)
	turn_vec.y = Input.get_joy_axis(player_no - 1, JOY_ANALOG_RY)
	turn_vec = dampen_joy_input(turn_vec)
	rotation_degrees.y -= sensitivity * turn_vec.x
	camera.rotation_degrees.x -= sensitivity * turn_vec.y
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -90, 90)
	
	match anim_state:
		ANIM_IDLE:
			if $MoveController.velocity.length_squared() > 0.1:
				set_anim_state_run()
		ANIM_RUNNING:
			if $MoveController.velocity.length_squared() < 0.1:
				set_anim_state_idle()

func _input(event):
	if event is InputEventJoypadButton and event.device == player_no - 1:
		match event.button_index:
			JOY_R2:
				if event.is_pressed():
					weapon_controller.attack()
				else:
					weapon_controller.stop_attack()
			JOY_L2:
				if event.is_pressed():
					weapon_controller.zoom()
				else:
					weapon_controller.unzoom()
			JOY_XBOX_A, JOY_SONY_X:
				move_controller.jump_pressed = true
			JOY_XBOX_B, JOY_SONY_CIRCLE:
				weapon_controller.melee()

func dampen_joy_input(input_vec: Vector3):
	if abs(input_vec.x) < joy_dampen:
		input_vec.x = 0.0
	if abs(input_vec.y) < joy_dampen:
		input_vec.y = 0.0
	if abs(input_vec.z) < joy_dampen:
		input_vec.z = 0.0
	return input_vec
	
func get_look_direction():
	return camera.rotation.x
	
func get_valid_targets():
	var targets = []
	for player in player_manager.players:
		if player and player != self:
			targets = targets + player.get_hitboxes()
	return targets
	
func interpolate_aim(basis: Basis, power: float, delta):
	var old = camera.global_transform.basis
	var quat = Quat(old.orthonormalized())
	var new = quat.slerp(Quat(basis), delta * autoaim_help * power)
	var euler = new.get_euler()
	rotation.y = euler.y
	camera.rotation.x = euler.x

func set_anim_state_run():
	anim_state = ANIM_RUNNING
	thirdpersonanim.play("run")

func set_anim_state_idle():
	anim_state = ANIM_IDLE
	thirdpersonanim.play("aim_gun")
	
func set_anim_state_pistolwhip():
	anim_state = ANIM_PISTOLWHIP
	thirdpersonanim.play("pistolwhip")
	firstpersonanim.play("MeleeAttack")
	
func finish_anim(anim):
	match anim:
		"pistolwhip":
			set_anim_state_idle()

func hurt(dmg_info):
	health_controller.hurt(dmg_info)
	
func health_changed(health_pct):
	screen.set_blood_opacity(1.0 - health_pct)

func dead(dmg_info):
	zoom_to(70.0)
	camera.set_remote_node("")
	player_manager.slay(player_no, dmg_info)
	
func get_hitboxes():
	return Util.find_all_children_with_type(self, "Hitbox")
	
func pickup(weaponid):
	return weapon_controller.change_weapon(weaponid)
	
func zoom_to(fov):
	var camera_path = get_path_to(camera_node)
	get_node(camera_path).fov = fov
	
func ladder(on: bool):
	move_controller.on_ladder = on
