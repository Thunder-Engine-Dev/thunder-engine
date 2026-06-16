extends CanvasLayer

signal complete

const SCAN_ROOT := "res://"

@onready var node_2d: Node2D = $Node2D

var _shader_materials: Array[ShaderMaterial] = []
var _particle_entries: Array[Dictionary] = []
var _seen_shader_keys: Dictionary = {}
var _seen_particle_keys: Dictionary = {}

var is_verbose: bool = ProjectSettings.get_setting("application/thunder_settings/verbose_shader_optimizing", false)


func _ready() -> void:
	compile()


func compile() -> void:
	_discover_shaders()
	_initialize_nodes()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.4, false, true, false).timeout
	complete.emit()


func _discover_shaders() -> void:
	_scan_dir(SCAN_ROOT)


func _scan_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	for file_name in dir.get_files():
		var real_file_name := file_name.replace(".remap", "")
		var full_path := dir_path.path_join(real_file_name)
		if real_file_name.ends_with(".tres"):
			_register_tres(full_path)
		elif real_file_name.ends_with(".gdshader"):
			_register_gdshader(full_path)

	for sub_dir in dir.get_directories():
		if sub_dir.begins_with("."):
			continue
		_scan_dir(dir_path.path_join(sub_dir))


func _register_tres(path: String) -> void:
	var resource := load(path)
	if resource is ShaderMaterial:
		_register_shader_material(resource)
	elif resource is ParticleProcessMaterial:
		_register_particle_material(resource)


func _register_gdshader(path: String) -> void:
	var shader := load(path) as Shader
	if shader == null:
		return
	var material := ShaderMaterial.new()
	material.shader = shader
	_register_shader_material(material)


func _register_shader_material(material: ShaderMaterial) -> void:
	if material.shader == null:
		return

	var key := _shader_key(material.shader)
	if _seen_shader_keys.has(key):
		return

	_seen_shader_keys[key] = true
	_shader_materials.append(material)


func _register_particle_material(material: Material, label: String = "") -> void:
	var key := label if label != "" else _particle_key(material)
	if _seen_particle_keys.has(key):
		return

	_seen_particle_keys[key] = true
	_particle_entries.append({
		"material": material,
		"label": label if label != "" else _particle_label(material),
	})


func _shader_key(shader: Shader) -> String:
	if shader.resource_path != "":
		return shader.resource_path
	return str(shader.get_rid())


func _particle_key(material: Material) -> String:
	if material.resource_path != "":
		return material.resource_path
	return str(material.get_rid())


func _shader_label(material: ShaderMaterial) -> String:
	if material.resource_path != "":
		return "%s (%s)" % [material.shader.resource_path, material.resource_path]
	if material.shader.resource_path != "":
		return material.shader.resource_path
	return "embedded (%s)" % material.shader.get_rid()


func _particle_label(material: Material) -> String:
	if material.resource_path != "":
		return material.resource_path
	return "embedded (%s)" % material.get_rid()


func _initialize_nodes() -> void:
	var index := 0

	for material in _shader_materials:
		if is_verbose:
			print("[ShaderOptimizer] Optimizing shader: %s" % _shader_label(material))
		var rect := ColorRect.new()
		rect.name = "Shader_%d" % index
		rect.size = Vector2(4, 4)
		rect.position = Vector2(-64, index * 4)
		rect.modulate.a = 0.0
		rect.material = material
		node_2d.add_child(rect)
		index += 1

	for entry in _particle_entries:
		if is_verbose:
			print("[ShaderOptimizer] Optimizing particles: %s" % entry["label"])
		var particles := GPUParticles2D.new()
		particles.name = "Particles_%d" % index
		particles.position = Vector2(-64, index * 4)
		particles.amount = 4
		particles.one_shot = true
		particles.explosiveness = 1.0
		particles.emitting = true
		particles.modulate.a = 0.0
		particles.process_material = entry["material"]
		node_2d.add_child(particles)
		index += 1

	print(
		"[ShaderOptimizer] Done: %d shaders, %d particle materials."
		% [_shader_materials.size(), _particle_entries.size()]
	)
