extends Node

var move_vec = Vector3.ZERO
var velocity = Vector3.ZERO
var drag: float
var jump_pressed = false
var grounded = false
var on_ladder = false

export(float) var max_speed = 1.0
export(float) var move_accel = 0.5
export(float) var ladder_speed = 5.0
export(bool) var ignore_rotation = false
export(float) var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
export(float) var jump_power = 20
export(float) var grip = 50.0

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
	if not on_ladder:
		if not ignore_rotation:
			cur_move_vec = cur_move_vec.rotated(Vector3.UP, body.rotation.y)
		velocity += move_accel * cur_move_vec - velocity * Vector3(drag, 0, drag)
		if abs(velocity.x) < delta * grip and abs(velocity.z) < delta * grip:
			velocity.x = 0
			velocity.z = 0
		velocity += Vector3.DOWN * gravity * delta
		var snap_direction
		if grounded:
			snap_direction = Vector3.DOWN * 1.5
		else:
			snap_direction = Vector3.ZERO
		velocity = body.move_and_slide_with_snap(velocity, snap_direction, Vector3.UP, true)

		grounded = body.is_on_floor()
		if grounded:
			velocity.y = -0.1
		if grounded and jump_pressed:
			velocity.y = jump_power
			grounded = false
		jump_pressed = false
	else:
		## On ladder
		if jump_pressed:
			on_ladder = false
		var up = Vector3()
		up.y = -cur_move_vec.z
		var coll = body.move_and_collide(up * ladder_speed * delta)
		if coll and up.y < 0:
			on_ladder = false
