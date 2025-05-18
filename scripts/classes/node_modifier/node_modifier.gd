@icon("./node_modifier.svg")
extends Node
class_name NodeModifier

@export var custom_target: NodePath
@export var target_base_class_name: String = "Node"

@onready var target_node: Node = get_node_or_null(custom_target) if custom_target else get_parent()

## Connecting the custom handlers of generic signals, not interfering with the custom code.
func _init() -> void:
	Thunder._connect(ready, _custom_ready)

## Checking if the base class of the target node is valid.
func _custom_ready() -> void:
	if !is_instance_valid(target_node):
		printerr("[NodeModifier]: Failed to retrieve the target node. Please check the target reference.")
	
	# TODO: check the base class here and print an error
