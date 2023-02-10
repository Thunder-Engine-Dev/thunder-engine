extends GDScript
class_name ByNodeScript

# Note: if you want to make a ByNodeScript activated, you should code like this:
# @onready var extra_script: Script = ByNodeScript.activate_script(custom_script, self)
# if you want to use _ready()-like functions in your ByNodeScripts, please override _instantiated_by() method
# other virtual methods are used as what they are when in Nodes, plus a param "by" in each virtual methods below

signal extra_script # Only used as an identifier, no other usage!

var node: Node
var vars: Dictionary
var other_nodes: Dictionary
var other_resources: Dictionary


static func activate_script(script: GDScript, by: Node, new_vars: Dictionary = {}, new_other_nodes: Dictionary = {}, new_other_resources: Dictionary = {}) -> GDScript:
	var result: GDScript
	if script:
		if script.has_script_signal(&"extra_script"):
			result = script.new(by, new_vars, new_other_nodes, new_other_resources)
		else:
			push_error("[Extra Script Error] Inserted script is not extended from ByNodeScript. Please check it")
	return result


func _init(by: Node, new_vars: Dictionary = {}, new_other_nodes: Dictionary = {}, new_other_resources: Dictionary = {}) -> void:
	if !by: return
	node = by
	vars = new_vars.duplicate(true)
	other_nodes = new_other_nodes.duplicate(true)
	other_resources = new_other_resources.duplicate(true)
	_ready()
	node.tree_entered.connect(_enter_tree)
	node.tree_exited.connect(_exit_tree)
	node.get_tree().process_frame.connect(_process.bind(node.get_process_delta_time()))
	node.get_tree().physics_frame.connect(_physics_process.bind(node.get_physics_process_delta_time()))


func _ready() -> void:
	pass

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass
