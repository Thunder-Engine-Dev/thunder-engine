extends RefCounted
class_name NodeCreator

## Useful [RefCounted]-extending object for adding 2D nodes

static func _instantiate_2d(pck: PackedScene) -> Node2D:
	if !pck: return null
	var node: Node2D = pck.instantiate() as Node2D
	return node

static func _create(ins: Node2D, on: Node2D, as_sibling: bool = true) -> void:
	if as_sibling: on.add_sibling(ins)
	elif Scenes.current_scene: Scenes.current_scene.add_child(ins)


## Used to create an 2D node from a [PackedScene] given
static func create_2d(pck: PackedScene, on:Node2D, as_sibling: bool = true, method_preready: Callable = Callable(), method_afteready: Callable = Callable()) -> NodeCreation:
	if !pck || !on: return null
	
	var ins: Node2D = _instantiate_2d(pck)
	if !ins: return null
	
	if method_preready: method_preready.call(ins)
	_create(ins,on,as_sibling)
	if method_afteready: method_afteready.call(ins)
	
	return NodeCreation.new(ins)

## Used to create an 2D node from a [InstanceNode2D] given
static func create_ins_2d(ins2d:InstanceNode2D, on:Node2D, as_sibling: bool = true, custom_vars: Dictionary = {}, script_before_ready: bool = false, method_preready: Callable = Callable(), method_afteready: Callable = Callable()) -> NodeCreation:
	if !ins2d || !on || !ins2d.creation_nodepack: return null
	
	var ins: Node2D = _instantiate_2d(ins2d.creation_nodepack)
	var creation_ref: NodeCreation = NodeCreation.new(ins)
	var created: Node2D = creation_ref.get_node()
	var script_call: Callable = func() -> void:
		var vars_list: Dictionary = ins2d.custom_vars
		vars_list.merge(custom_vars)
		vars_list.merge({spawner = on})
		creation_ref.execute_script(ins2d.custom_script, vars_list) as Node2D
	
	if method_preready: method_preready.call(ins2d)
	if script_before_ready: script_call.call()
	_create(ins,on,as_sibling)
	if method_afteready: method_afteready.call(ins2d)
	if !script_before_ready: script_call.call()
	
	created.global_position = on.global_transform.translated_local(ins2d.trans_offset).get_origin()
	created.global_rotation = ins2d.trans_rotation
	created.global_scale = ins2d.trans_scale
	created.global_skew = ins2d.trans_skew
	
	if ins2d.trans_inheritances & 001 == 001:
		created.global_rotation += on.global_rotation
	if ins2d.trans_inheritances & 010 == 010:
		created.global_scale *= on.global_scale
	if ins2d.trans_inheritances & 100 == 100:
		created.global_skew += on.global_skew
	
	return creation_ref


## A [RefCounted]-extending object that includes methods to operate the instance created more deeply
class NodeCreation extends RefCounted:
	var _node: Node
	
	func _init(node: Node) -> void:
		_node = node
	
	func get_node() -> Node:
		return _node
	
	func execute_script(custom_script: GDScript, custom_vars: Dictionary = {}) -> Node:
		if !custom_script: return _node
		var _scr: Script = ByNodeScript.activate_script(custom_script, _node, custom_vars)
		return _node
