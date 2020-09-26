extends ViewportContainer

func set_blood_opacity(opacity: float):
	$Blood.modulate.a = opacity
	
func follow_ragdoll(ragdoll: Spatial):
	$Viewport/Camera.follow_tgt = ragdoll
	$Viewport/Camera.follow = true

func stop_follow():
	$Viewport/Camera.follow = false
	$Viewport/Camera.rotation = Vector3.ZERO
