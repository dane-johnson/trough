extends KinematicBody

export(int) var player_no = 1
export(float) var sensitivity = 2.5
export(float) var joy_dampen = 0.1
export(float) var mouse_sensitivity = 0.4
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
var local = false

## For detecting mouse movement
var mouse_movement = Vector2.ZERO

enum {ANIM_IDLE, ANIM_RUNNING, ANIM_PISTOLWHIP}
var anim_state = ANIM_IDLE

func _ready():
	if local:
		setup_local_player()
	else:
		setup_remote_player()
		
	move_controller.init(self)
	weapon_controller.init(self)
	health_controller.init(self)
	
	for hitbox in get_hitboxes():
		hitbox.connect("hurt", self, "hurt")
		
	thirdpersonanim.connect("animation_finished", self, "finish_anim")
	
	var skin_opts = $CharacterModel.skins.keys()
	$CharacterModel.skin = skin_opts[0]
	$CharacterModel.update_skin()

func setup_local_player():
	var camera_path = get_path_to(camera_node)
	camera.set_remote_node("../" + camera_path)
	firstperson_mask = 0x1
	thirdperson_mask = 0x2
	Util.set_person_mask(self, "both", thirdperson_mask, firstperson_mask)
	get_node(camera_path).set_cull_mask(0x1 | firstperson_mask)


func setup_remote_player():
	firstperson_mask = 0x2
	thirdperson_mask = 0x1
	Util.set_person_mask(self, "both", thirdperson_mask, firstperson_mask)

func get_movement_vec():
	var move_vec = Vector3.ZERO
	move_vec.x = Input.get_joy_axis(player_no - 1, JOY_ANALOG_LX)
	move_vec.z = Input.get_joy_axis(player_no - 1, JOY_ANALOG_LY)
	move_vec = dampen_joy_input(move_vec)

	move_vec.x += Input.get_action_strength("strafe_right") - Input.get_action_strength("strafe_left")
	move_vec.z += Input.get_action_strength("run_backwards") - Input.get_action_strength("run_forwards") 

	return move_vec

func get_turn_vec():
	var turn_vec = Vector3.ZERO
	turn_vec.x = Input.get_joy_axis(player_no - 1, JOY_ANALOG_RX)
	turn_vec.y = Input.get_joy_axis(player_no - 1, JOY_ANALOG_RY)
	turn_vec = dampen_joy_input(turn_vec)

	turn_vec.y += mouse_movement.y * mouse_sensitivity
	turn_vec.x += mouse_movement.x * mouse_sensitivity
	mouse_movement = Vector2.ZERO

	return turn_vec

func _process(_delta):
	if not local:
		return
	# Handle inputs
	var move_vec = get_movement_vec()
	move_controller.move_vec = move_vec

	var turn_vec = get_turn_vec()
	rotation_degrees.y -= sensitivity * turn_vec.x
	camera.rotation_degrees.x -= sensitivity * turn_vec.y
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -90, 90)

	handle_input()
	
	var flat_vel = Vector3(move_controller.velocity.x, 0.0, move_controller.velocity.z)
	rpc("update_anim", flat_vel, false)

remotesync func update_anim(flat_vel: Vector3, pistolwhip: bool):
	match anim_state:
		ANIM_IDLE:
			if pistolwhip:
				set_anim_state_pistolwhip()
			elif flat_vel.length_squared() > 0.1:
				set_anim_state_run()
		ANIM_RUNNING:
			if pistolwhip:
				set_anim_state_pistolwhip()
			elif flat_vel.length_squared() < 0.1:
				set_anim_state_idle()
		ANIM_PISTOLWHIP:
			pass ## Nothing stops a pistolwhip

func handle_input():
	if Input.is_action_just_pressed("attack"):
		weapon_controller.attack()
	elif Input.is_action_just_released("attack"):
		weapon_controller.stop_attack()

	if Input.is_action_just_pressed("zoom"):
		weapon_controller.zoom()
	elif Input.is_action_just_released("zoom"):
		weapon_controller.unzoom()

	if Input.is_action_just_pressed("jump"):
		move_controller.jump_pressed = true
		
	if Input.is_action_just_pressed("melee"):
		weapon_controller.melee()

func _input(event):
	if not local:
		return
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
				
	if event is InputEventMouseMotion:
		mouse_movement += event.relative

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
	for player in player_manager.get_player_instances():
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
	health_controller.rpc("hurt", dmg_info)
	
func health_changed(health_pct):
	if screen:
		screen.set_blood_opacity(1.0 - health_pct)

func dead(dmg_info):
	if local:
		zoom_to(70.0)
		camera.set_remote_node("")
	player_manager.slay(self, dmg_info)
	
func get_hitboxes():
	return Util.find_all_children_with_type(self, "Hitbox")
	
func pickup(weaponid):
	return weapon_controller.change_weapon(weaponid)
	
func zoom_to(fov):
	var camera_path = get_path_to(camera_node)
	get_node(camera_path).fov = fov
	
func ladder(on: bool):
	move_controller.on_ladder = on
