extends RefCounted
class_name NodeCreator

## Useful [RefCounted]-extending object for adding 2D nodes

static func _instantiate_2d(pck: PackedScene) -> Node2D:
	if !pck: return null
	var node: Node2D = pck.instantiate() as Node2D
	return node

## Used to create an 2D node from a [PackedScene] given
static func prepare_2d(pck: PackedScene, on:Node2D) -> NodeCreation:
	if !pck || !on: return NodeCreation.new(null, null)
	
	var ins: Node2D = _instantiate_2d(pck)
	if !ins: return NodeCreation.new(null, on)
	
	return NodeCreation.new(ins, on)

## Used to create an 2D node from a [InstanceNode2D] given
static func prepare_ins_2d(ins2d:InstanceNode2D, on:Node2D) -> NodeCreation:
	if !ins2d || !on || !ins2d.creation_nodepack: return NodeCreation.new(null, null)
	
	var ins: Node2D = _instantiate_2d(ins2d.creation_nodepack)
	if !ins: return NodeCreation.new(null, on)
	
	return NodeCreation.new(ins, on, ins2d)


## A [RefCounted]-extending object that includes methods to operate the instance created more deeply
class NodeCreation extends RefCounted:
	var _node: Node2D
	var _on: Node2D
	var _ins2d: InstanceNode2D
	
	func _init(node: Node2D, on: Node2D, ins2d: InstanceNode2D = null) -> void:
		_node = node
		_on = on
		_ins2d = ins2d
	
	
	func get_node() -> Node2D:
		return _node
	
	func call_method(method: Callable) -> NodeCreation:
		if !_node: return self
		if method: method.call(_node)
		return self
	
	func execute_script(custom_script: GDScript, custom_vars: Dictionary = {}) -> NodeCreation:
		if !_node || !custom_script: return self
		var _scr: Script = ByNodeScript.activate_script(custom_script, _node, custom_vars)
		return self
	
	func execute_instance_script(custom_vars: Dictionary = {}, which_method: StringName = &"") -> NodeCreation:
		if !_node || !_ins2d.custom_script: return self
		var vars: Dictionary = custom_vars
		vars.merge(_ins2d.custom_vars)
		var scr: Script = ByNodeScript.activate_script(_ins2d.custom_script, _node, vars)
		if which_method in scr.get_script_method_list(): scr.call(which_method)
		return self
	
	func bind_global_transform(offset: Vector2 = Vector2.ZERO, rot: float = 0, scl: Vector2 = Vector2.ONE, skew: float = 0) -> NodeCreation:
		if !_node || !_on: return self
		_node.global_transform = _on.global_transform.translated_local(offset).rotated(rot).scaled(scl)
		_node.skew = _on.global_skew
		return self
	
	func create_2d(as_sibling: bool = true, ins2d: InstanceNode2D = null) -> NodeCreation:
		if !_node: return self
		
		if as_sibling: _on.add_sibling(_node)
		elif Scenes.current_scene: Scenes.current_scene.add_child(_node)
		
		if ins2d: _ins2d = ins2d
		if !_ins2d: return self
		
		_node.global_position = _on.global_transform.translated_local(_ins2d.trans_offset).get_origin()
		_node.global_rotation = _ins2d.trans_rotation
		_node.global_scale = _ins2d.trans_scale
		_node.global_skew = _ins2d.trans_skew
		
		if _ins2d.trans_inheritances & 001 == 001:
			_node.global_rotation += _on.global_rotation
		if _ins2d.trans_inheritances & 010 == 010:
			_node.global_scale *= _on.global_scale
		if _ins2d.trans_inheritances & 100 == 100:
			_node.global_skew += _on.global_skew
		
		print(_node.global_position)
		
		return self
