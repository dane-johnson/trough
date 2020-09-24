extends Node

var move_vec = Vector3.ZERO
var velocity = Vector3.ZERO
var drag: float
var jump_pressed = false
var grounded = false

export(float) var max_speed = 5.0
export(float) var move_accel = 1.0
export(bool) var ignore_rotation = false
export(float) var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
export(float) var jump_power = 10.0

var body


func _ready():
	assert(max_speed - move_accel > 0, "Cannot set move_accel faster than max_speed!")
	drag = move_accel / max_speed

func init(_body: KinematicBody):
	move_vec = Vector3.ZERO
	velocity = Vector3.ZERO
	body = _body

func _physics_process(delta):
	var cur_move_vec = move_vec
	if not ignore_rotation:
		cur_move_vec = cur_move_vec.rotated(Vector3.UP, body.rotation.y)
	velocity += move_accel * cur_move_vec - velocity * Vector3(drag, 0, drag)
	velocity += Vector3.DOWN * gravity * delta
	var snap_direction
	if grounded:
		snap_direction = Vector3.DOWN
	else:
		snap_direction = Vector3.ZERO
	velocity = body.move_and_slide_with_snap(velocity, snap_direction, Vector3.UP)

	grounded = body.is_on_floor()
	if grounded:
		velocity.y = -0.01
	if grounded and jump_pressed:
		velocity.y = jump_power
		grounded = false
	jump_pressed = false
