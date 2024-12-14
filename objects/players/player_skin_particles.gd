extends GPUParticles2D

func _ready() -> void:
	update_particles()
	SkinsManager.skins_loaded.connect(update_particles)


func update_particles():
	var global_skin_tweaks = CharacterManager.get_misc_texture("global_skin_tweaks")
	if !global_skin_tweaks || !global_skin_tweaks is Dictionary: return
	var mat: Dictionary = global_skin_tweaks.get("particles_process_material")
	if !mat: return
	
	var particle_tex = CharacterManager.get_misc_texture("particle")
	if particle_tex:
		texture = particle_tex
	
	var new_mat: ParticleProcessMaterial = process_material.duplicate()
	new_mat.particle_flag_disable_z = mat.particle_flag_disable_z
	match mat.emission_shape:
		"point":
			new_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		"box":
			new_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		_:
			new_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	new_mat.emission_sphere_radius = mat.emission_sphere_radius
	new_mat.emission_box_extents = _get_vector(mat.emission_box_extents)
	new_mat.angle_min = mat.angle_min
	new_mat.angle_max = mat.angle_max
	new_mat.direction = _get_vector(mat.direction)
	new_mat.spread = mat.spread
	new_mat.initial_velocity_min = mat.initial_velocity_min
	new_mat.initial_velocity_max = mat.initial_velocity_max
	new_mat.gravity = _get_vector(mat.gravity)
	new_mat.scale_min = mat.scale_min
	new_mat.scale_max = mat.scale_max
	new_mat.hue_variation_min = mat.hue_variation_min
	new_mat.hue_variation_max = mat.hue_variation_max
	
	process_material = new_mat


func _get_vector(arr: Variant) -> Vector3:
	if !arr is Array: return Vector3.ZERO
	if arr.is_empty(): return Vector3.ZERO
	return Vector3(arr.front(), arr.back(), 0)
