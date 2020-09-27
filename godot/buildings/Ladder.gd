extends Spatial

func _ready():
	$Lift.connect("body_entered", self, "attach")
	$Lift.connect("body_exited", self, "detach")
	
func attach(ply: Node):
	if ply.has_method("ladder"):
		ply.ladder(true)
	
func detach(ply: Node):
	if ply.has_method("ladder"):
		ply.ladder(false)
