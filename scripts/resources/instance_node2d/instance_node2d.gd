# Create a Node2D with physics and some other parameters
extends Resource
class_name InstanceNode2D

## A kind of [Resource] that stores a [PackedScene], whose root is a [Node2D], that you need to add[br]
## You need to call [method NodeCreator.prepare_ins_2d] and input the resource as the first parameter to instantiate
## and create the node packed in [member creation_nodepack]

@export_category("InstanceNode2D")
@export_group("Creation","creation_")
## The [Node2D] you have packed as the root, also the instance you are going to add via [method NodeCreator.prepare_ins_2d]
@export var creation_nodepack: PackedScene
@export_group("Transform","trans_")
## The offset of the created, related to its [member Node2D.global_transform]
@export var trans_offset: Vector2
## The flags for transform properties that you want the created to inherit
@export_flags("inherit_rotation","inherit_scale","inherit_skew") var trans_inheritances: int
## [member Node2D.global_rotation] of the created, if [code]inherit_rotation[/code] ticked, it will rotate from the creator's
@export var trans_rotation: float
## [member Node2D.global_scale] of the created, if [code]inherit_scale[/code] ticked, it will be scaled by the creator's
@export var trans_scale: Vector2 = Vector2.ONE
## [member Node2D.global_skew] of the created, if [code]inherit_skew[/code] ticked, it will be sheared from the creator's
@export var trans_skew: float
@export_group("Visibility","visi_")
## [member CanvasItem.visible] of the created
@export var visi_z_index: int
## [member CanvasItem.z_as_relative] of the created
@export var visi_z_as_relative: bool = true
## [member CanvasItem.y_sort_enabled] of the created
@export var visi_y_sort_enabled: bool
@export_group("Extension")
## Custom variables for [member custom_script]
@export var custom_vars: Dictionary
## Custom script executed when [method NodeCreator.execute_instance_script] is called
@export var custom_script: GDScript


func _report_resource() -> void:
	printerr("[Report] The error happened on: " + str(get_rid()) + ", with path:" + resource_path)
