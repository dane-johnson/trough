extends Spatial

export var is_ragdoll = false
export var kick = Vector3.ZERO
var should_cleanup = false

func _ready():
	$CleanupTimer.connect("timeout", self, "cleanup")
	if is_ragdoll:
		ragdoll(kick)

func cleanup():
	should_cleanup = true

func ragdoll(impulse = Vector3.ZERO):
	is_ragdoll = true
	$Armature/Skeleton/Hand/WeaponSocket.get_child(0).queue_free()
	$Armature/Skeleton.physical_bones_start_simulation()
	$Armature/Skeleton/Ragdoll/Body.apply_central_impulse(impulse)
	$CleanupTimer.start()

func _physics_process(delta):
	if is_ragdoll and should_cleanup:
		if $Armature/Skeleton/Ragdoll/Body.velocity.length_squared() < 0.01:
			queue_free()
