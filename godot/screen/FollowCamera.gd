extends Camera


export var follow = false
var follow_tgt: Spatial = null

func _process(_delta):
	if follow:
		print(follow_tgt.global_transform.origin)
		look_at(follow_tgt.global_transform.origin, Vector3.UP)
