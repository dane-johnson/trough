extends Spatial

class_name Gun

var can_attack = true
export var attack_rate = 1.0
export var damage = 30.0
export var automatic = false
export var zoom = 1.0
var attack_timer: Timer
var firing = false
var sound_level = 1.0
var min_sound_level = 0.0

signal attack

func _ready():
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.connect("timeout", self, "attack_done")
	add_child(attack_timer)
	$MuzzleFlash/Timer.connect("timeout", $MuzzleFlash, "hide")

func attack():
	if automatic:
		firing = true
	if can_attack:
		emit_signal("attack")
		can_attack = false
		$MuzzleFlash.show()
		$MuzzleFlash/Timer.start()
		$MuzzleFlash.rotate_z(rand_range(0, 2 * PI))
		$ShotSound.volume_db = 10 * (sound_level - 1)
		$ShotSound.play()
		sound_level *= 0.9
		attack_timer.start(attack_rate)
		
func stop_attack():
	firing = false
	sound_level = 1.0
	
func attack_done():
	can_attack = true
	if firing:
		attack()
