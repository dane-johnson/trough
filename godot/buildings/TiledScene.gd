extends Spatial
tool

export(PackedScene) var prefab setget set_prefab
export(int) var reps = 1 setget set_reps
export(Vector3) var offset_direction setget set_offset_direction

func update_children():
	if not prefab:
		return
		
	for child in get_children():
		child.queue_free()
	var pos = Vector3.ZERO
	for i in range(reps):
		var inst = prefab.instance()
		add_child(inst)
		inst.transform.origin = pos
		pos += offset_direction

func set_prefab(_prefab):
	prefab = _prefab
	update_children()
	
func set_reps(_reps):
	reps = _reps
	update_children()
	
func set_offset_direction(_offset_direction):
	offset_direction = _offset_direction
	update_children()
