extends Node

signal dead

export(int) var max_health = 100
var current_health
var dead = false

var player

func init(_player):
	player = _player
	current_health = max_health

func hurt(dmg_info):
	if dead:
		return
	current_health -= dmg_info["dmg"]
	if current_health <= 0:
		dead = true
		emit_signal("dead")
		player.dead(dmg_info)

func heal(heal_info):
	if dead:
		return
	else:
		current_health = min(current_health + heal_info["health"], max_health)
		
