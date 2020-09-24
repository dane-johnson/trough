extends Area


class_name Hitbox

export(float) var damage_multiplier = 1.0

signal hurt

func get_autoaim_tgt():
	var tgt = get_node_or_null("AutoaimTarget")
	if not tgt:
		tgt = self
	return tgt

func get_class():
	return "Hitbox"
	
func hurt(dmg_info):
	dmg_info["dmg"] *= damage_multiplier
	emit_signal("hurt", dmg_info)
