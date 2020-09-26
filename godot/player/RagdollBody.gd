extends PhysicalBone

var velocity: Vector3 = Vector3.ZERO

#HACK this function is undocumented
func _direct_state_changed(bodystate):
	# Super
	._direct_state_changed(bodystate)
	velocity = bodystate.linear_velocity
