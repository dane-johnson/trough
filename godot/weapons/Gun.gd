extends Spatial

class_name Gun

var can_attack = true
export var attack_rate = 1.0
var attack_timer: Timer

signal attack

func _ready():
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.connect("timeout", self, "attack_done")
	add_child(attack_timer)
	$MuzzleFlash/Timer.connect("timeout", $MuzzleFlash, "hide")

func attack():
	if can_attack:
		emit_signal("attack")
		can_attack = false
		$MuzzleFlash.show()
		$MuzzleFlash/Timer.start()
		$ShotSound.play()
		attack_timer.start()
		
func attack_done():
	can_attack = true
