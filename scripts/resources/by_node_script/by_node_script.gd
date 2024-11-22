extends GDScript
class_name ByNodeScript

## A kind of [GDScript] that supports fast access to nodes, variables, and resources[br]
## [b]Note:[/b] You need a variable assigned with [code]static[/code] [method activate_script]
## to make the script you firstly set instantiated and work
## [codeblock]
## @export var custom_script: GDScript = preload(...)
## # Defined a custom script, but it won't work right in the game
## #
## @onready var custom_script_instance: ByNodeScript = ByNodeScript.activate_script(custom_script,node) 
## # This will make custom_script works
## [/codeblock]

## Only used as an identifier, no other usage!
signal extra_script

enum _NodeNotification {
	NODE_READY,
	NODE_ENTER_TREE,
	NODE_EXIT_TREE,
	NODE_PROCESS,
	NODE_PHYSICS_PROCESS
}

## Root node of the script to do fast access
var node: Node
## Optinal variables of the script to do fast access
var vars: Dictionary

## Used to activate a resource script[br]
## [param script] is that resource script you need to make be running[br]
## [param by] is the node you need to bind as the root node to get fast access[br]
## [param new_vars] is [i]optinal[/i], used to give the script the vars to use
static func activate_script(script: GDScript, by: Node, new_vars: Dictionary = {}) -> GDScript:
	var result: GDScript
	if script:
		if script.has_script_signal(&"extra_script"):
			result = script.new(by, new_vars)
		else:
			push_error("[Extra Script Error] Inserted script is not extended from ByNodeScript. Please check it")
	return result


func _init(by: Node, new_vars: Dictionary = {}) -> void:
	if !is_instance_valid(by):
		return
	
	node = weakref(by).get_ref()
	vars = new_vars
	
	node.tree_entered.connect(_script_notification.bind(_NodeNotification.NODE_ENTER_TREE))
	node.tree_exited.connect(_script_notification.bind(_NodeNotification.NODE_EXIT_TREE))
	
	_script_notification(_NodeNotification.NODE_READY)
	
	if !node.is_inside_tree(): 
		await node.ready
	node.get_tree().process_frame.connect(_script_notification.bind(_NodeNotification.NODE_PROCESS))
	node.get_tree().physics_frame.connect(_script_notification.bind(_NodeNotification.NODE_PHYSICS_PROCESS))


func _script_notification(what: _NodeNotification) -> void:
	if !is_instance_valid(node):
		node = null
		return
	match what:
		_NodeNotification.NODE_READY:
			_ready()
		_NodeNotification.NODE_ENTER_TREE:
			_enter_tree()
		_NodeNotification.NODE_EXIT_TREE:
			_exit_tree()
		_NodeNotification.NODE_PROCESS when node.can_process():
			_process(node.get_process_delta_time())
		_NodeNotification.NODE_PHYSICS_PROCESS when node.can_process():
			_physics_process(node.get_physics_process_delta_time())


## [code]@virtual[/code] called by [member node]'s [method Node._ready]
func _ready() -> void:
	pass

## [code]@virtual[/code] called by [member node]'s [method Node._enter_tree]
func _enter_tree() -> void:
	pass

## [code]@virtual[/code] called by [member node]'s [method Node._exit_tree]
func _exit_tree() -> void:
	pass

## [code]@virtual[/code] called by [member node]'s [method Node._process][br]
## [b]Note:[/b] sometimes you need to assign a variable to get delta:[br]
## [code]delta: float = node.get_process_delta_time()[/code]
func _process(delta: float) -> void:
	pass

## [code]@virtual[/code] called by [member node]'s [method Node._physics_process][br]
## [b]Note:[/b] sometimes you need to assign a variable to get delta:[br]
## [code]delta: float = node.get_physics_process_delta_time()[/code]
func _physics_process(delta: float) -> void:
	pass
