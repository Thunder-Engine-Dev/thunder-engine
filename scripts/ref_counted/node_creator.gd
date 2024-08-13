extends RefCounted
class_name NodeCreator

## Useful [RefCounted]-extending object for adding 2D nodes
##
## You are allowed to directly add a [Node2D], or add it via
## [InstanceNode2D]


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
static func prepare_ins_2d(ins2d: InstanceNode2D, on:Node2D) -> NodeCreation:
	if !ins2d || !on || !ins2d.creation_nodepack: return NodeCreation.new(null, null)
	
	var ins: Node2D = _instantiate_2d(ins2d.creation_nodepack)
	if !ins: return NodeCreation.new(null, on)
	
	return NodeCreation.new(ins, on, ins2d)


## A [RefCounted]-extending object that includes methods to operate the instance's creating
class NodeCreation extends RefCounted:
	var _node: Node2D
	var _on: Node2D
	var _ins2d: InstanceNode2D
	
	
	func _init(node: Node2D, on: Node2D, ins2d: InstanceNode2D = null) -> void:
		_node = node
		_on = on
		_ins2d = ins2d
	
	
	## Return [Node2D] assigned via calling [method NodeCreator.prepare_2d] or [method NodeCreator.prepare_ins_2d]
	func get_node() -> Node2D:
		return _node
	
	
	## Call an [Callable] method for the instance[br]
	## [b]Warning:[/b] the method you are calling should contain a parameter in [Node2D] type as the first param of it
	func call_method(method: Callable) -> NodeCreation:
		if !_node: return self
		if method: method.call(_node)
		return self
	
	
	## Execute an [GDScript] extending from [ByNodeScript] with [param custom_vars]
	func execute_script(custom_script: GDScript, custom_vars: Dictionary = {}) -> NodeCreation:
		if !_node || !custom_script: return self
		var _scr: Script = ByNodeScript.activate_script(custom_script, _node, custom_vars)
		return self
	
	
	## Execute an [member InstanceNode2D.custom_script] input with [param custom_vars][br]
	## If [param which_method] in the script exists, the method will be called before its [method ByNodeScript._ready] if available
	func execute_instance_script(custom_vars: Dictionary = {}, which_method: StringName = &"") -> NodeCreation:
		if !_node || !_ins2d.custom_script: return self
		var vars: Dictionary = custom_vars
		vars.merge(_ins2d.custom_vars)
		var scr: Script = ByNodeScript.activate_script(_ins2d.custom_script, _node, vars)
		if which_method in scr.get_script_method_list(): scr.call(which_method)
		return self
	
	
	## If you haven't called [method NodeCreator.prepare_ins_2d], then you need to call this function
	## to set the [member Node2D.global_transform] of the node input[br]
	## It's also allowed to call it before or after you call [method create_2d]
	func bind_global_transform(offset: Vector2 = Vector2.ZERO, rot: float = 0, scl: Vector2 = Vector2.ONE, skew: float = 0) -> NodeCreation:
		if !_node || !_on: return self
		_node.global_transform = _on.global_transform.translated_local(offset).rotated(rot).scaled(scl)
		_node.skew = _on.global_skew
		return self
	
	
	## Execute adding the node input to the tree[br]
	## If you called [method NodeCreator.prepare_ins_2d] with [param ins2d] input, the function will automatically make the node 
	## input inherit the transform properties in [InstanceNode2D][br]
	## If [param ins2d] input, the input one will override the existing one
	func create_2d(as_sibling: bool = false, ins2d: InstanceNode2D = null) -> NodeCreation:
		if !_node: return self
		
		if as_sibling: _on.add_sibling(_node)
		elif Scenes.current_scene: Scenes.current_scene.add_child(_node)
		
		if ins2d: _ins2d = ins2d
		if !_ins2d: return self
		
		_node.global_position = _on.global_transform.translated_local(_ins2d.trans_offset).get_origin()
		_node.global_rotation = _ins2d.trans_rotation
		_node.global_scale = _ins2d.trans_scale
		_node.global_skew = _ins2d.trans_skew
		
		_node.z_index = _ins2d.visi_z_index
		_node.z_as_relative = _ins2d.visi_z_as_relative
		_node.y_sort_enabled = _ins2d.visi_y_sort_enabled
		
		if _ins2d.trans_inheritances & 001 == 001:
			_node.global_rotation += _on.global_rotation
		if _ins2d.trans_inheritances & 010 == 010:
			_node.global_scale *= _on.global_scale
		if _ins2d.trans_inheritances & 100 == 100:
			_node.global_skew += _on.global_skew
		
		return self
