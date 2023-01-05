extends GDScript
class_name ByNodeScript

# Note: if you want to make a ByNodeScript activated, you should code like this:
# @onready var extra_script:Script = ByNodeScript.activate_script(custom_script,self)
# if you want to use _ready()-like functions in your ByNodeScripts, please override _instantiated_by() method
# other virtual methods are used as what they are when in Nodes, plus a param "by" in each virtual methods below

signal extra_script # Only used as an identifier, no other usage!

var node:Node


static func activate_script(script:GDScript,by:Node) -> GDScript:
	var result:GDScript
	if script:
		if script.has_script_signal(&"extra_script"):
			result = script.new(by)
		else:
			push_error("[Extra Script Error] Script inserted is not extended from ByNodeScript. Please check it")
	return result


func _init(by:Node) -> void:
	if !by: return
	node = by
	_instantiated_by(node)
	node.tree_entered.connect(_enter_tree_by.bind(node))
	node.get_tree().process_frame.connect(_process_by.bind(node.get_process_delta_time(),node))
	node.get_tree().physics_frame.connect(_physics_process_by.bind(node.get_physics_process_delta_time(),node))


# _ready()
func _instantiated_by(by:Node) -> void:
	pass

# _enter_tree()
func _enter_tree_by(by:Node) -> void:
	pass

# _exit_tree()
func _exit_tree_by(by:Node) -> void:
	pass

# _process(delta)
func _process_by(delta:float,by:Node) -> void:
	pass

# _physics_process(delta)
func _physics_process_by(delta:float,by:Node) -> void:
	pass
