extends KinematicBody

export(int) var player_no = 1
export(float) var sensitivity = 2.5
export(float) var joy_dampen = 0.1

onready var move_controller = $MoveController
onready var weapon_controller = $WeaponController
onready var camera = $CameraRemote
var camera_node

enum {ANIM_IDLE, ANIM_RUNNING}
var anim_state = ANIM_IDLE

func _ready():
	move_controller.init(self)
	weapon_controller.init(self)
	var camera_path = get_path_to(camera_node)
	camera.set_remote_node("../" + camera_path)
	var firstperson_mask = 0x1 << (player_no)
	var thirdperson_mask = 0x1e & ~(firstperson_mask)
	Util.set_person_mask(self, "both", thirdperson_mask, firstperson_mask)
	get_node(camera_path).set_cull_mask(0x1 | firstperson_mask)

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
		if event.button_index == JOY_R2 and event.is_pressed():
			$WeaponController.attack()
		elif event.button_index == JOY_XBOX_A or event.button_index == JOY_SONY_X:
			move_controller.jump_pressed = true

func dampen_joy_input(input_vec: Vector3):
	if abs(input_vec.x) < joy_dampen:
		input_vec.x = 0.0
	if abs(input_vec.y) < joy_dampen:
		input_vec.y = 0.0
	if abs(input_vec.z) < joy_dampen:
		input_vec.z = 0.0
	return input_vec

func set_anim_state_run():
	anim_state = ANIM_RUNNING
	$CharacterModel/AnimationPlayer.play("run")

func set_anim_state_idle():
	anim_state = ANIM_IDLE
	$CharacterModel/AnimationPlayer.play("aim_gun")

func hurt():
	pass
