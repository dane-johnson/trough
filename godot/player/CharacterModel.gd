extends Spatial

export var is_ragdoll = false
export var kick = Vector3.ZERO
var min_time = false

export(String) var skin = "austin"

var skins = {
	"austin": preload("res://player/raw/austin_skin.png"),
	"cole": preload("res://player/raw/cole_skin.png")
}

signal cleanup

func _ready():
	$Armature/Skeleton/Cube.get_surface_material(0).albedo_texture = skins[skin]
	if is_ragdoll:
		ragdoll(kick)
	$CleanupTimerNoMove.connect("timeout", self, "min_time_reached")
	$CleanupTimerMoving.connect("timeout", self, "cleanup")

func ragdoll(impulse = Vector3.ZERO):
	is_ragdoll = true
	if $Armature/Skeleton/Hand/WeaponSocket.get_child_count() == 1:
		$Armature/Skeleton/Hand/WeaponSocket.get_child(0).queue_free()
	$Armature/Skeleton.physical_bones_start_simulation()
	$Armature/Skeleton/Ragdoll/Body.apply_central_impulse(impulse)
	$CleanupTimerNoMove.start()
	$CleanupTimerMoving.start()

func _physics_process(delta):
	if is_ragdoll and min_time:
		if $Armature/Skeleton/Ragdoll/Body.velocity.length_squared() < 0.01:
			cleanup()
			
func min_time_reached():
	min_time = true

func cleanup():
	emit_signal("cleanup")

func get_ragdoll_tgt():
	return $Armature/Skeleton/Ragdoll/Body
