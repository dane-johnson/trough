extends Object

class_name Util

static func set_person_mask(current: Node, mode: String, thirdperson_mask: int, firstperson_mask: int):
	var groups = current.get_groups()
	for group in groups:
		if group == "firstperson":
			mode = "firstperson"
		if group == "thirdperson":
			mode = "thirdperson"
	if current is VisualInstance:
		if mode == "firstperson":
			current.set_layer_mask(firstperson_mask)
		elif mode == "thirdperson":
			current.set_layer_mask(thirdperson_mask)
		else:
			current.set_layer_mask(firstperson_mask | thirdperson_mask)
	for child in current.get_children():
		set_person_mask(child, mode, thirdperson_mask, firstperson_mask)

static func find_all_children_with_type(current: Node, type:String):
	var nodes = []
	if current.get_class() == type:
		nodes.append(current)
	for child in current.get_children():
		nodes = nodes + find_all_children_with_type(child, type)
	return nodes
