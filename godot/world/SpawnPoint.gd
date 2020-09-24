extends Area

func can_spawn():
	return get_overlapping_bodies().size() == 0
