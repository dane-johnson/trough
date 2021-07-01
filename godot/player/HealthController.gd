extends Node

signal dead

export(int) var max_health = 100
export(int) var heal_rate = 5
var current_health
var dead = false

var player
var heal_timer: Timer

func init(_player):
	player = _player
	current_health = max_health
	heal_timer = Timer.new()
	add_child(heal_timer)
	heal_timer.connect("timeout", self, "heal", [{"health": heal_rate}])
	heal_timer.start(0.5)

remotesync func hurt(dmg_info):
	if dead:
		return
	current_health -= dmg_info["dmg"]
	player.health_changed(float(current_health) / max_health)
	if current_health <= 0:
		dead = true
		emit_signal("dead")
		player.dead(dmg_info)

func heal(heal_info):
	if dead:
		return
	else:
		current_health = min(current_health + heal_info["health"], max_health)
		player.health_changed(float(current_health) / max_health)
		
