extends GPUParticles2D

const DEFAULT_GLOBAL_SKIN_TWEAKS: Dictionary = {
	"particles_process_material": {
		"particle_flag_disable_z": true,
		"emission_shape": "sphere",
		"emission_sphere_radius": 24,
		"emission_box_extents": [1, 1],
		"angle_min": -180,
		"angle_max": 180,
		"direction": [1, 0],
		"spread": 180,
		"initial_velocity_min": 25,
		"initial_velocity_max": 75,
		"gravity": [0, 0],
		"scale_min": 0.1,
		"scale_max": 0.3,
	}
}

@onready var global_skin_tweaks = CharacterManager.get_misc_texture("global_skin_tweaks")

func _ready() -> void:
	if !global_skin_tweaks || !global_skin_tweaks is Dictionary: return
	var mat: Dictionary = global_skin_tweaks.get("particles_process_material")
	if !mat: return
	
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
	
	process_material = new_mat


func _get_vector(arr: Variant) -> Vector3:
	if !arr is Array: return Vector3.ZERO
	if arr.is_empty(): return Vector3.ZERO
	return Vector3(arr.front(), arr.back(), 0)
