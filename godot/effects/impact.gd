extends Spatial


func emit(normal: Vector3, blood=false):
	$Particles.process_material.direction = normal
	if blood:
		$Particles.process_material.color = Color("ff0505")
	else:
		$Particles.process_material.color = Color("50341d")
	$Particles.emitting = true
