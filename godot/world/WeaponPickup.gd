extends Spatial

tool

export(PackedScene) var model
export(int) var weaponid
export(bool) var temporary = false

func _ready():
	var weapon = model.instance()
	$WeaponSocket.add_child(weapon)
	$Area.connect("body_entered", self, "pickup")
	$RespawnTimer.connect("timeout", self, "respawn")
	if temporary:
		$DecayTimer.connect("timeout", self, "queue_free")
		$DecayTimer.start()
	
func pickup(ply):
	var accept = ply.pickup(weaponid)
	if temporary and accept:
		queue_free()
	elif accept:
		$WeaponSocket.hide()
		$Area.set_deferred("monitoring", false)
		$RespawnTimer.start()
		
func respawn():
	$WeaponSocket.show()
	$Area.monitoring = true
