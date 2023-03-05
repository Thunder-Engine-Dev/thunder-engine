extends RefCounted
class_name NodeCreator

## Useful [RefCounted]-extending object for adding 2D nodes

## Used to create an 2D node from a [PackedScene]
static func create_2d(pck:PackedScene, on:Node2D, as_sibling: bool = true, method_preready: Callable = Callable(), method_afteready: Callable = Callable()) -> NodeCreation:
	if !pck || !on: return null
	
	var ins: Node2D = pck.instantiate()
	if !ins: return null
	
	if method_preready: method_preready.call(ins)
	
	if as_sibling: on.add_sibling(ins)
	elif Scenes.current_scene: Scenes.current_scene.add_child(ins)
	
	if method_afteready: method_afteready.call(ins)
	
	return NodeCreation.new(ins)


## A [RefCounted]-extending object that includes methods to operate the instance created more deeply
class NodeCreation extends RefCounted:
	var _node: Node
	
	func _init(node: Node) -> void:
		_node = node
	
	func get_node() -> Node:
		return _node
	
	func execute_script(custom_script: GDScript, custom_vars: Dictionary = {}, custom_nodes: Dictionary = {}, custom_resources: Dictionary = {}) -> Node:
		if !custom_script: return
		var _scr: ByNodeScript = ByNodeScript.activate_script(custom_script, _node, custom_vars, custom_nodes, custom_resources)
		return _node
